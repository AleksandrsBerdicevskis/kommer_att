local dir `c(pwd)'

use logistic_models, clear
drop if command == "not converged"



gen tsplit = "non-consecutive split"
replace tsplit = "consecutive split" if split == 1

*Find best train accuracy per model
bysort corpus model split: egen max_train_accuracy = max(train_accuracy)

order max train_a

keep if train_accuracy == max_train_accuracy

*In case there are more than one models with same accuracy, select the model with the lowest AIC
sort corpus model split AIC
by corpus model split: keep if _n == 1

drop max
bysort corpus split: egen max_test_accuracy = max(test_accuracy)
bysort split corpus: egen best = max(test_accuracy)

gen tbest = " "
replace tbest = "*" if best == test_accuracy 

gen stringmodel = "M_I"
replace stringmodel = "M_II"  if model == 2
replace stringmodel = "M_III"  if model == 3
replace stringmodel = "M_IV"  if model == 4

gen tmodel = stringmodel+tbest

drop if corpus == "synthetic"

*Separate figures per tsplit

keep if split == `1'

if `1' == 1 {
	local title consecutive
	local graph_title figure2
	}
if `1' == 2 {
	local title non_consecutive
	local graph_title figure_C1
	}	
	

replace corpus = ustrupper(corpus)
levelsof corpus, local(corpora)
local text

foreach corpus of local corpora {
		preserve
		keep if corpus == "`corpus'"
		
		graph hbar (asis) test_accuracy, over(tmodel, label(labsize(*1.2)) sort(model) gap(5)) blabel(bar, format(%3.2f) position(base) color(white) size(*1.05)) nofill graphregion(color(white)) ///  
		scheme(s2mono) yscale(nofextend) ylabel(0 20 40 60 80,nogrid) ytitle(" ") title("`corpus'") nodraw saving(`corpus'.gph, replace) yscale(nofextend) 
		local text "`text' `corpus'.gph"
		restore
	}

graph combine `text', graphregion(color(white))	cols(2) ///
b1title("Correctly predicted test data (%)") ysize(3) xsize(2)


graph export `graph_title'.png, replace height(3000)
window manage close graph

gen perc_diff = test_accuracy


foreach corpus of local corpora { 
	cap erase `corpus'.gph
	sum test_accuracy if model == 1 & corpus == "`corpus'"
	replace perc_diff = perc_diff - r(mean) if corpus == "`corpus'"
}

keep if tbest == "*"
drop if perc_diff == 0
gen string = string(perc_diff,"%4.2f")


sort corpus model

list corpus tmodel string

exit
		


