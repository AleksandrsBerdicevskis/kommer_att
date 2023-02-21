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

gen stringmodel = "I"
replace stringmodel = "II"  if model == 2
replace stringmodel = "III"  if model == 3
replace stringmodel = "IV"  if model == 4

gen tmodel = stringmodel+tbest

drop if corpus == "synthetic"

order corpus stringmodel tp tn fp fn split 
keep corpus stringmodel tp tn fp fn split

sort split corpus stringmodel

gen tsplit = "consecutive"
replace tsplit = "non_consecutive" if split == 2
drop split 
order tsplit

label var tsplit "Type of split"
label var corpus "Corpus"
label var stringmodel "Model"
label var tp "True positives"
label var tn "True negatives"
label var fp "False positives"
label var fn "False negatives"

export excel using "confusion_table", replace firstrow(varlabels)

exit