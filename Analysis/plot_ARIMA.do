local dir `c(pwd)'

local type `1'

if "`1'" == "full_sample" {
	local graph_title figure4
	}
if "`1'" == "one_step" {
	local graph_title figure5
	}	
 
local text
foreach corpus in `"all"' `"bloggmix"' `"da"' `"familjeliv"' `"flashback"' `"gp"' `"svt"' `"twitter"'   {
	
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
	
	
	local title = upper("`corpus'")
	
	
	tw 	(tsline outcome if test == 0, lwidth(*2.8) lcolor(black) lpattern(solid)) ///
			(tsline outcome if test == 1, lwidth(*2.8) lcolor(lime) lpattern(solid)) ///
			(tsline forecast_M_I, 				lwidth(*2.8) lcolor(pink) lpattern(solid))	///
			(tsline forecast_M_II, 				lwidth(*2.8) lcolor(blue) lpattern(solid))	///
				,  ///
			legend(position(6) symxsize(*.45) keygap() ///
			order(1 2 3 4) cols(2)  ///
			label(1 "Train") ///
			label(2 "Test") ///
			label(3 "M_I`Mtext_1'") ///
			label(4 "M_II`Mtext_2'") ///
			region(color(white)) size(large)) ///
			ytitle("") ttitle("") graphregion(color(white)) ///
			yscale(nofextend) xscale(nofextend) ylabel(,nogrid) tlabel(#2) ///
			saving(`corpus'.gph, replace) nodraw scheme(s2mono) title("`title'")
			local text `"`text' `corpus'.gph"'
		}
graph combine `text', scheme(s2mono) graphregion(color(white)) cols(2) b1title("Month") l1title("Proportion of omissions")	iscale(*.65) ///
	imargin(2 2 2 2) ysize(3) xsize(2)  
		

graph export tochange.svg, replace
filefilter tochange.svg totransform.svg, from(`"stroke-width:5.24"') to(`"stroke-width:5.00; opacity:.65"') replace 
		
capture erase `graph_title'.png
			
*Use inkscape to transform svg into png
!inkscape "`dir'/totransform.svg" --without-gui --export-dpi=1800 --export-png  "`dir'/`graph_title'.png"                                                

window manage close graph

foreach file in `text'	tochange.svg totransform.svg	{
	cap erase `file'
}
exit

