*Read in data 

local dir `c(pwd)'

capture mkdir raw


import delimited "kommer_att_predictors_all.tsv", delimiter(tab) bindquote(nobind) stripquote(no) case(preserve) encoding(UTF-8) clear 
save kommer_att_predictors_all, replace

*Draw 1 percent pseudorandom sample for testing purposes
set seed 42
sample 1
save kommer_att_predictors_all_1percent, replace


*Generate corpora for each maincorpus
use maincorpus using kommer_att_predictors_all, clear
levelsof maincorpus
local maincorpus = r(levels)
foreach corpus of local maincorpus {
	use if maincorpus == "`corpus'" using kommer_att_predictors_all, clear
	gen outcome = 1
	replace outcome = 0 if status == "att"
	
	label define vals 1 "omission" 0 "att"
	
	label values outcome vals

	
	compress
	
	save `dir'/raw/`corpus'_raw, replace
	}	
	
exit	