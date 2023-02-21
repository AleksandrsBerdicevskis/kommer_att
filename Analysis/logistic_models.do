set more off, perm
local dir `c(pwd)'
local corpus 	`1'
local model 	`2'
local fp_spec `3'
local split 	`4'
local igroup 	`5'


*Dataset to store the accuracy information
clear 
set obs 100
gen double cutoff = .
gen double train_accuracy = .
save `dir'/logistic_models/`corpus'_`model'_`fp_spec'_`split', replace

if `split' == 1 {
	use samples/`corpus'_sample_consecutive, clear
}
else {
	use samples/`corpus'_sample_non_consecutive, clear
}


/*
*For all models that include 'month' as covariate, we parameterize 'month' in three different ways: 
0 - linear
1 - a degree-1 fractional polynomial with automatically chosen power by fitting 8 models
2 - a degree-2 fractional polynomial with automatically chosen powers by fitting 44 models
3 - a degree-3 fractional polynomial with automatically chosen powers by fitting 164 models

For test data prediction, we will choose the model with the best training data accuracy
From the Stata manual:
By default, fp will fit degree-2 fractional polynomial (FP2) models and choose the fractional powers
from the set {-2, -1,-0.5,0,0.5,1,2,3}.
*/

if `fp_spec' == 0 {
	local fp_text `"dimension(1) powers(1)"'
}
if `fp_spec' == 1 {
	local fp_text `"dimension(1)"'
}
if `fp_spec' == 2 {
	local fp_text `"dimension(2)"'
}
if `fp_spec' == 3 {
	local fp_text `"dimension(3)"'
}

if `model' == 2 {
	local covariates
}

if (`model' == 3 | `model' == 4) {
	local covariates `"subject voice att_before att_after att_interaction distance_to_att_words inf_length"'
}

capture noisily {
if `model' == 1 {
	logit outcome if test == 0
}

if `model' == 2   {
	fp <month>, `fp_text' classic : logit outcome <month>  if test == 0
	*Extract command line to generate new variables that include the test data
	local command = e(fp_gen_cmdline)
	*Drop already generated variables
	cap drop month_* 
	*Generate fp2
	`command'
	*Fit model
	logit outcome month_*  if test == 0
}
if `model' == 3  {
	
		*Degree-2 fractional polynomial for attraction (trained without inclusion of 'month')
		fp <attraction>, dimension(2) classic : logit outcome <attraction> `covariates' if test == 0, iterate(10)
		*Extract command line to generate new variables that include the test data
		local attraction_command = e(fp_gen_cmdline)
		*Drop already generated variables
		cap drop attraction_* 
		*Generate fp2
		`attraction_command'
	
		fp <month>, `fp_text' classic : logit outcome <month> `covariates' attraction_* if test == 0
		*Extract command line to generate new variables that include the test data
		local command = e(fp_gen_cmdline)
		*Drop already generated variables
		cap drop month_* 
		*Generate fp2
		`command'

		*Fit model
		logit outcome month_* `covariates' attraction_* if test == 0
	
}

if `model' == 4  {
	
		*Degree-2 fractional polynomial for attraction (trained without inclusion of 'month')
		fp <attraction>, dimension(2) classic : logit outcome <attraction> `covariates' if test == 0, iterate(10)
		*Extract command line to generate new variables that include the test data
		local attraction_command = e(fp_gen_cmdline)
		*Drop already generated variables
		cap drop attraction_* 
		*Generate fp2
		`attraction_command'
	
		fp <month>, `fp_text' classic : logit outcome c.<month>##(`covariates' c.attraction_1 c.attraction_2) if test == 0
		*Extract command line to generate new variables that include the test data
		local command = e(fp_gen_cmdline)
		*Drop already generated variables
		cap drop month_* 
		*Generate fp2
		`command'
	
		
		*Specificy interactions depending on degree of fractional polynomial and fit models with interactions
		if (`fp_spec' == 0 | `fp_spec' == 1) {
			logit outcome ///
				c.month_1##(`covariates' c.attraction_1 c.attraction_2) ///
				if test == 0
		}
		if (`fp_spec' == 2) {
			logit outcome ///
				c.month_1##(`covariates' c.attraction_1 c.attraction_2) ///
				c.month_2##(`covariates' c.attraction_1 c.attraction_2) ///
				if test == 0
		}
		if (`fp_spec' == 3) {
			logit ///
				c.month_1##(`covariates' c.attraction_1 c.attraction_2) ///
				c.month_2##(`covariates' c.attraction_1 c.attraction_2) ///
				c.month_3##(`covariates' c.attraction_1 c.attraction_2) ///
				if test == 0
		}

}

}
if _rc == 0 {
	local logit_command = e(cmdline)
	*Compute AIC
	estat ic
	mat ic=r(S)
	local AIC = ic[1,5]
		* For proportion approach : save predicted proportions
		preserve
		*Predict probability per observation with rules option
		predict phat_`model', rules
		
		*Calculate average per month & test
		
		collapse outcome phat, by(month test)
		
		*Calc accuracy measure
		*log (prediction/actual)^2 https://doi.org/10.1057/jors.2014.103
		gen double acc_ratio=(log(phat/outcome))^2 
		
		sum acc_ratio if test==1
		local acc_ratio_test 	= sqrt(r(sum))*100/r(N)
		
		sum acc_ratio if test==0
		local acc_ratio_train = sqrt(r(sum))*100/r(N)  
		
		drop acc_ratio
		
		save `dir'/logistic_proportions/`corpus'_`model'_`fp_spec'_`split', replace	 
		restore
	
	/*
	Find best accuracy cutoff for training_data via:
	estat classification, cutoff(.75)
	r(P corr) percent correctly classified
	
	Use 'best' cutoff to predict test_data and record accuracy
	*/
	quietly {
	forvalues i = 25/75 {
		noisily di "corpus: `corpus' | model: `model' | cutoff: `i'%"
		preserve
		local cutoff = `i'/100
		estat classification if test == 0, cutoff(`cutoff')
		local accuracy = r(P_corr)
		use 	`dir'/logistic_models/`corpus'_`model'_`fp_spec'_`split', clear
		replace train_accuracy = `accuracy' in `i'
		replace cutoff = `cutoff' in `i'
		save 	`dir'/logistic_models/`corpus'_`model'_`fp_spec'_`split', replace
		restore
	}
	}
	*Find maximum
	preserve
	use 	`dir'/logistic_models/`corpus'_`model'_`fp_spec'_`split', clear
	sum train_accuracy
	keep if train_accuracy == r(max)
	
	*Sample 1 in case there are more than one with similar accuracy
	set seed 523941
	sample 1, count
	
	local cutoff  = cutoff[1]
	local train_accuracy = train_accuracy[1]
	restore
	
	*Check for training
	estat classification if test == 1, cutoff(`cutoff') 
	local test_accuracy = r(P_corr) 
	
	*Information for confusion matrix https://towardsdatascience.com/understanding-confusion-matrix-a9ad42dcfd62
	mat ctable = r(ctable)
	local tp = ctable[1,1]
	local tn = ctable[2,2]
	local fn = ctable[2,1]
	local fp = ctable[1,2]
	
	
	*Prepare finished file
	clear
	set obs 1
	gen corpus = "`corpus'"
	gen model  = `model'
	gen fp_spec = `fp_spec'
	gen split = `split'
	gen cutoff = `cutoff'
	gen command = "`command'"
	gen logit_command = "`logit_command'"
	if `model' == 3  {
			gen attraction_command = "`attraction_command'" 
		}
	gen train_accuracy	= `train_accuracy'
	gen test_accuracy		= `test_accuracy'
	gen tp	= `tp'
	gen tn	= `tn'
	gen fn 	= `fn'
	gen fp 	= `fp'
	
	gen acc_ratio_train	= `acc_ratio_train'
	gen acc_ratio_test	= `acc_ratio_test'
	gen AIC = `AIC'
	save finished_`igroup', replace
	clear
}
else { 
	*Prepare finished file
	clear
	set obs 1
	gen corpus = "`corpus'"
	gen model  = `model'
	gen fp_spec = `fp_spec'
	gen split = `split'
	gen cutoff = .
	gen command = "not converged"
	gen train_accuracy	= .
	gen test_accuracy		= .
	gen acc_ratio_train	= .
	gen acc_ratio_test	= .
	gen AIC = . 
	gen logit_command = ""
	save finished_`igroup', replace
	clear
	
}        
exit, STATA 	
exit
