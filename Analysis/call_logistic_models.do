local dir `c(pwd)'

capture mkdir logistic_models
capture mkdir logistic_proportions

use logistic_overview, clear

*Add information for "synthetic"

set obs 9 

replace corpus 	= "synthetic"		in 9
replace sample 	= 100000			in 9
replace first		= 2004			in 9
replace last		= 2021			in 9
replace	train		=	5			in 9

*3 models: 1 -no covariates / 2 - month as covariate / 3 - month and all other predictors as covariates / 4 - month, all other predictors as covariates & interactions
expand 4

bysort corpus: gen model = _n

*4 specifications regarding the parameterization of <month>: 0 - linear | 1 - fp dimension(1) | 2 -fp dimension(2) | 3 -fp dimension(3)
expand 4
bysort corpus model: gen fp_spec = _n-1

*2 train/test splits: 1 - consecutive | 2 - non consecutive
expand 2
bysort corpus model fp_spec: gen split = _n

save TEMP, replace

gen randorder = runiform()
sort randorder
drop randorder


save cTEMP, replace

foreach split in 1 2 {
	use if split == `split' using cTEMP, clear
	local min=1
	local max=_N 
	forvalues i = `min'/`max' {	
	di "split-`split': `i' of `max'"
	preserve
	local corpus 	= 	corpus[`i']
	local model		= 	model[`i']
	local fp_spec = 	fp_spec[`i']
	local split 	= 	split[`i']
	winexec xstata-mp -q do logistic_models `corpus' `model' `fp_spec' `split' `i'
	sleep 2000
	restore
}
	



clear         
/* wait until everything is finished */
clear
 forvalues i=`min'/`max' {  
   capture confirm file "finished_`i'.dta"
   while _rc != 0 {
      sleep 2000
      capture confirm file "finished_`i'.dta"
   }
 }

use finished_1.dta, clear
drop in 1/l

forvalues i=`min'/`max' {	
	append using finished_`i'
	capture erase "finished_`i'.dta"
}

save TEMP_`split', replace
}

use TEMP_1, clear

append using TEMP_2


erase cTEMP.dta


merge 1:1 corpus model fp_spec split using TEMP, nogenerate
erase TEMP.dta


export delimited using "logistic_models", delimiter(tab) replace
save logistic_models, replace

exit
