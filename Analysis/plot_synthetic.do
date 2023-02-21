local dir `c(pwd)'

*C.gph + D.gph

foreach type in full_sample one_step {
		local title C
	if "`type'" == "one_step" {
		local title D
	}
	
	local corpus synthetic	
	*Prepare one dataset per corpus
	import delimited samples/`corpus'_no_exog_`type'_ARIMA.csv, clear 
	
	keep month test outcome forecast
	rename forecast forecast_M_I
	save TEMP, replace
	
	import delimited samples/`corpus'_exog_`type'_ARIMA.csv, clear 
	
	keep test month outcome forecast
	rename forecast forecast_M_II
	
	merge 1:1 month using TEMP, nogen
	cap erase TEMP.dta
	
	split month, p(m)
	drop month
	rename month1 year
	rename month2 month
	gen month_n=monthly(year+"m"+month,"YM")
	tsset month_n, monthly	
	
	foreach ftype in M_I M_II {
		*Calculate ACC
		gen double ACC_`ftype' = (log(forecast_`ftype'/outcome))^2 
		qui sum ACC_`ftype' if test==1
		local ACC_`ftype' = sqrt(r(sum))*100/r(N)
	}
	*Find minimum
	
	if `ACC_M_I' < `ACC_M_II' {
	local ACC_M_I : di %4.2f `ACC_M_I'	
	local ACC_M_II: di %4.2f `ACC_M_II'	
	local Mtext_1 `"* (`ACC_M_I')"'
	local Mtext_2 `" (`ACC_M_II')"'
	} 
	if `ACC_M_I' == `ACC_M_II' {
	local ACC_M_I : di %4.2f `ACC_M_I'	
	local ACC_M_II: di %4.2f `ACC_M_II'	
	local Mtext_1 `"* (`ACC_M_I')"'
	local Mtext_2 `"* (`ACC_M_II')"'
	}	
	if `ACC_M_I' > `ACC_M_II' {
	local ACC_M_I : di %4.2f `ACC_M_I'	
	local ACC_M_II: di %4.2f `ACC_M_II'	
	local Mtext_1 `" (`ACC_M_I')"'
	local Mtext_2 `"* (`ACC_M_II')"'
	}		

		*local ACC_`i': di %4.2f `ACC_`i''
		*local Mtext_`i' `"`asterisk' (`ACC_`i'')"' 
	
	
	tw 	(tsline outcome if test == 0, lwidth(*2.8) lcolor(black) lpattern(solid)) ///
			(tsline outcome if test == 1, lwidth(*2.8) lcolor(lime) lpattern(solid)) ///
			(tsline forecast_M_I, 				lwidth(*2.8) lcolor(pink) lpattern(solid))	///
			(tsline forecast_M_II, 				lwidth(*2.8) lcolor(blue) lpattern(solid))	///
				,  ///
			legend(position(6) symxsize(*.45) keygap() ///
			order(1 2 3 4) cols(4)  ///
			label(1 "Train") ///
			label(2 "Test") ///
			label(3 "M_I`Mtext_1'") ///
			label(4 "M_II`Mtext_2'") ///
			region(color(white)) ) ///
			ytitle("") ttitle("") graphregion(color(white)) ///
			yscale(nofextend) xscale(nofextend) ylabel(,nogrid) tlabel(#2) ///
			saving(`title'.gph, replace) nodraw scheme(s2mono) title("{bf:`title'}", position(10))
			
		}	

*B.gph

use logistic_models, clear

*Only consecutive
keep if split == 1

*Find best train accuracy per model
bysort corpus model: egen min_acc_ratio_train = min(acc_ratio_train)


keep if acc_ratio_train == min_acc_ratio_train

*In case there are more than one models with same accuracy, sample 1
set seed 127093
sample 1, by(corpus model) count 

gen asterisk = " "



keep if corpus == "synthetic"
local corpus synthetic

forvalues i = 1/4 {
	sum fp_spec if model == `i'
	local fp_spec_`i' = r(mean)
}

*Prepare one dataset per corpus
use `dir'/logistic_proportions/`corpus'_1_`fp_spec_1'_1, clear
drop phat_1

forvalues i = 1/4 {
	merge 1:1 month using  `dir'/logistic_proportions/`corpus'_`i'_`fp_spec_`i''_1, nogenerate
	replace phat_`i' = . if test == 0
	
	*Calculate ACC
	gen double ACC_`i' = (log(phat_`i'/outcome))^2 

}

forvalues i = 1/4 {
	qui sum ACC_`i' if test==1
	local ACC_`i' = sqrt(r(sum))*100/r(N)
}
*Find minimum
local minimum = min(`ACC_1',`ACC_2',`ACC_3',`ACC_4' )

forvalues i = 1/4 {
	if `ACC_`i'' == `minimum' {
		local asterisk "*"
	}
	else {
		local asterisk " "
	}
	
	local ACC_`i': di %4.2f `ACC_`i''
	local Mtext_`i' `"`asterisk' (`ACC_`i'')"' 
}

*Add a little jitter to improve visibility
replace phat_3 = 1.005*phat_3
replace phat_4 = 1.009*phat_4


tsset month, monthly

	tw 	(tsline outcome if test == 0, lcolor(black) 	lwidth(*2.8) lpattern(solid)) ///
			(tsline outcome if test == 1, lcolor(lime) 		lwidth(*2.8) lpattern(solid)) ///
			(tsline phat_1, lcolor(pink) 									lwidth(*2.8) lpattern(solid))	///
			(tsline phat_2, lcolor(orange) 								lwidth(*2.8) lpattern(solid))	///
			(tsline phat_3, lcolor(blue) 									lwidth(*2.8) lpattern(solid))	///
			(tsline phat_4, lcolor(sandb) 									lwidth(*2.8) lpattern(solid)) ///	
				,  ///
			legend(position(6) symxsize(*.45) keygap() ///
			order(1 2 3 4 5 6) cols(4)  ///
			label(1 "Train") ///
			label(2 "Test") ///
			label(3 "M_I`Mtext_1'") ///
			label(4 "M_II`Mtext_2'") ///
			label(5 "M_III`Mtext_3'") ///
			label(6 "M_IV`Mtext_4'") ///
		region(color(white)) ) ///
		ytitle("") ttitle("") graphregion(color(white)) ///
		yscale(nofextend) xscale(nofextend) ylabel(,nogrid) tlabel(#2) ///
		saving(B.gph, replace) scheme(s2mono) title("{bf:B}", position(10))

*A.gph
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

keep if corpus == "synthetic"

*Separate figures per tsplit

keep if split == 1

graph hbar (asis) test_accuracy, over(tmodel, label(labsize(*1.2)) sort(model)) blabel(bar, format(%3.2f) position(base) color(white)  size(*1.05)) nofill graphregion(color(white)) ///  
scheme(s2mono) yscale(nofextend) ylabel(,nogrid) ytitle(" ") title("{bf:A}", position(10)) nodraw saving(A.gph, replace) yscale(nofextend) 

*Combine
graph combine A.gph B.gph C.gph D.gph, graphregion(color(white)) iscale(*.95) cols(1) ysize(3) xsize(1.5)

graph export tochange.svg, replace
filefilter tochange.svg totransform.svg, from(`"stroke-width:6.46"') to(`"stroke-width:6.00; opacity:.65"') replace 

capture erase figure_D1.png
			
*Use inkscape to transform svg into png
!inkscape "`dir'/totransform.svg" --without-gui --export-dpi=1800 --export-png  "`dir'/figure_D1.png"                                                

window manage close graph

foreach file in A.gph B.gph C.gph D.gph	tochange.svg totransform.svg	{
	cap erase `file'
}


exit