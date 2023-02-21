version 14.2

*Prepare selected datasets

local dir `c(pwd)'

capture mkdir samples

clear
set obs 8

gen corpus 			= ""
gen sample			= .
gen first 			= .
gen last 				= .
gen train				= .  /// number of last years used as test data

*Note: check test/training split

replace corpus 	= "bloggmix" 	 	in 1
replace sample 	= 5000				in 1
replace first		= 2005			in 1
replace last		= 2016			in 1
replace	train		=	3			in 1
                               	
replace corpus 	= "da"			 	in 2
replace sample 	= 1000				in 2
replace first		= 2013			in 2
replace last		= 2021			in 2
replace	train		=	2			in 2
                               	
replace corpus 	= "familjeliv" 		in 3
replace sample 	= 60000				in 3
replace first		= 2004			in 3
replace last		= 2020			in 3
replace	train		=	4			in 3
                               	
replace corpus 	= "flashback" 		in 4
replace sample 	= 80000				in 4
replace first		= 2005			in 4
replace last		= 2021			in 4
replace	train		=	4			in 4
                               	
replace corpus 	= "gp" 				in 5
replace sample 	= 13000				in 5
replace first		= 2001			in 5
replace last		= 2013			in 5
replace	train		=	3			in 5
                               	
replace corpus 	= "svt" 			in 6
replace sample 	= 8000				in 6
replace first		= 2007			in 6
replace last		= 2021			in 6
replace	train		=	3			in 6
                               	
replace corpus 	= "twitter"			in 7
replace sample 	= 6000				in 7
replace first		= 2009			in 7
replace last		= 2018			in 7
replace	train		=	2			in 7

replace corpus 	= "all"				in 8
replace sample 	= 100000			in 8
replace first		= 2004			in 8
replace last		= 2021			in 8
replace	train		=	5			in 8


save logistic_overview, replace

local till = _N
foreach training_type in  non_consecutive consecutive {
		forvalues i = 1/`till' {
			use logistic_overview, clear
			local corpus 	= corpus[`i']
			local sample 	= sample[`i']
			local first 	= first[`i']
			local last		= last[`i']
			local train		= train[`i']
			
			if "`corpus'" == "all" {
				use  if year>= `first' & year<= `last' using kommer_att_predictors_all, clear
				gen outcome = 1
				replace outcome = 0 if status == "att"
			
			}
			else {
				use if year>= `first' & year<= `last' using raw/`corpus'_raw, clear
			}
			
			
			set seed 476929
			sample `sample', by(year) count
			
			gen test = 0
			
			if "`training_type'" == "consecutive" {
				*Consecutive split
				replace test = 1 if year >= (`last'-`train')+1  
			}
			else {
				*Non-consecutive 80/20 split
				set seed 640849
				gen split_random = runiform()
				replace test = 1 if split_random >= .8 
				drop split_random
			}
			
			
			*Generate binary variables 
			foreach var in voice subject att_before att_after genre {
			encode `var' , gen(`var'_bin)
			*Generate binary variable
			replace `var'_bin = 0 if `var'_bin == 2
			drop `var'
			rename `var' `var'
			label val `var'
			}
			
			*Recode for subject att_before att_after (0 – no; 1 – yes)
			foreach var in subject att_before att_after  {
				recode `var' (0 = 1) (1 = 0)
			}
			
			*Generate interaction between att_before & att_after
			gen att_interaction = att_before * att_after
			
			*Inf length will also be recoded to 0 ==> 1 or 1 ==> '2 or more'
			gen TEMP=0
			replace TEMP = 1 if inf_length>1
			
			drop inf_length
			rename TEMP inf_length
			
			*Same for distance to att_words
			gen TEMP = 0
			replace TEMP = 1 if distance_to_att_words>1
			
			drop distance_to_att_words
			rename TEMP distance_to_att_words
		
			
			
			
			gen month_n=monthly(string(year)+"m"+string(month),"YM")	
			rename month M_month
			rename month_n month
			
			keep global_id outcome year month M_month subject voice att_before att_after att_interaction distance_to_att_words inf_length genre test verb_lemma
			
			*Compute attraction based on the training data only
			*For verb_lemmas that occur in the test data but not in the training data, we assume an occurence frequency of 1 and impute a corresponding value
			
			preserve
			keep if test == 0
			bysort verb_lemma: gen long numerator=_N
			gen double attraction = numerator/_N
			
			save TEMP_training, replace
			
			*Get value for missing verb_lemmas to use for imputation
			sum attraction if numerator == 1
			local attraction_imputation = r(mean)
			
			*Now sample 1 by verb_lemma
			sample 1, by(verb_lemma) count
			*keep verb_lemma and attraction
			keep verb_lemma attraction
			save TEMP_to_merge, replace
			restore
			keep if test == 1
			*Merge
			merge m:1 verb_lemma using TEMP_to_merge, keep(1 3) nogenerate
			*Replace empty values
			replace attraction = `attraction_imputation' if attraction == .
			*Append training data
			append using TEMP_training
			
			
			compress
			save samples/`corpus'_sample_`training_type', replace
			
			drop verb numerator
			
			preserve 
			drop month
			rename M_month month
			order global_id year month
			label drop _all
			export delimited using "samples/`corpus'_sample_`training_type'.csv", delimiter(tab) replace
			restore
			
			zipfile  "samples/`corpus'_sample_`training_type'.csv", saving("samples/`corpus'_sample_`training_type'.zip", replace)
			
			
			if "`training_type'" == "consecutive" {
				*For Arima analysis, prepare monthly corpora
				
				
				gen long datapoints = 1
		  	
				gcollapse outcome subject voice att_before att_after att_interaction distance_to_att_words inf_length genre attraction (sum) datapoints, by(month test) fast
				
				tsset month, monthly
				
				
				order month
				
				compress
				save samples/`corpus'_monthly_sample_`training_type', replace 
				export delimited using "samples/`corpus'_monthly_sample.csv", delimiter(tab) replace
				}
			
		}
}

cap erase TEMP_training.dta
cap erase TEMP_to_merge.dta
exit
