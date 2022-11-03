local dir `c(pwd)'

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



 
local text
foreach corpus in `"all"' `"bloggmix"' `"da"' `"familjeliv"' `"flashback"' `"gp"' `"svt"' `"twitter"'   {
	preserve
	keep if corpus == "`corpus'"
	
	forvalues i = 1/3 {
		sum fp_spec if model == `i'
		local fp_spec_`i' = r(mean)
	}
	
	*Prepare one dataset per corpus
	use `dir'/logistic_proportions/`corpus'_1_`fp_spec_1'_1, clear
	drop phat_1
	
	forvalues i = 1/3 {
		merge 1:1 month using  `dir'/logistic_proportions/`corpus'_`i'_`fp_spec_`i''_1, nogenerate
		replace phat_`i' = . if test == 0
		
		*Calculate ACC
		gen double ACC_`i' = (log(phat_`i'/outcome))^2 
	
	}
	
	forvalues i = 1/3 {
		qui sum ACC_`i' if test==1
		local ACC_`i' = sqrt(r(sum))*100/r(N)
	}
	*Find minimum
	local minimum = min(`ACC_1',`ACC_2',`ACC_3')
	
	forvalues i = 1/3 {
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

local title = upper("`corpus'")
	
	tsset month, monthly
	
	tw 	(tsline outcome if test == 0, lcolor(black) 	lwidth(*2.8) lpattern(solid)) ///
			(tsline outcome if test == 1, lcolor(lime) 		lwidth(*2.8) lpattern(solid)) ///
			(tsline phat_1, lcolor(pink) 									lwidth(*2.8) lpattern(solid))	///
			(tsline phat_2, lcolor(orange) 								lwidth(*2.8) lpattern(solid))	///
			(tsline phat_3, lcolor(blue) 									lwidth(*2.8) lpattern(solid))	///
				,  ///
			legend(position(6) symxsize(*.45) keygap() ///
			order(1 2 3 4 5) cols(2)  ///
			label(1 "Train") ///
			label(2 "Test") ///
			label(3 "M_I`Mtext_1'") ///
			label(4 "M_II`Mtext_2'") ///
			label(5 "M_III`Mtext_3'") ///
			region(color(white)) size(large)) ///
			ytitle("") ttitle("") graphregion(color(white)) ///
			yscale(nofextend) xscale(nofextend) ylabel(,nogrid) tlabel(#2) ///
			saving(`corpus'.gph, replace) nodraw scheme(s2mono) title("`title'", size(*1.2))
			local text `"`text' `corpus'.gph"'
		restore
		}
graph combine `text',  scheme(s2mono) graphregion(color(white)) cols(2) ///
b1title("Month") l1title("Proportion of omissions")	iscale(*.65) ///
imargin(2 2 2 2) ysize(3) xsize(2) 
		

graph export tochange.svg, replace

filefilter tochange.svg totransform.svg, from(`"stroke-width:5.24"') to(`"stroke-width:5.00; opacity:.65"') replace 
		
capture erase figure2.png
			
*Use inkscape to transform svg into png
!inkscape "`dir'/totransform.svg" --without-gui --export-dpi=1800 --export-png  "`dir'/figure2.png"                                                

window manage close graph

foreach file in `text'	tochange.svg totransform.svg	{
	cap erase `file'
}
exit

