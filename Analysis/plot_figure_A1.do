local dir `c(pwd)'

use samples/twitter_monthly_sample_consecutive, clear

tsset month, monthly

tssmooth ma outcome_ma = outcome, window(3 1 3)


	tw 	(tsline outcome, lwidth(*1.2) lcolor(gs10) lpattern(solid)) ///
			(tsline outcome_ma, lwidth(*1.5) lcolor(blue) lpattern(solid)) ///
		,  ///
			legend(position(6) symxsize(*.45) keygap() ///
			cols(2)  ///
			label(1 "Observed") ///
			label(2 "Moving average") ///
			region(color(white)) size(large)) ///
			ytitle("Proportion of omissions") ttitle("Month") graphregion(color(white)) ///
			yscale(nofextend) xscale(nofextend) ylabel(,nogrid)  ///
			scheme(s2mono) tline(2017m11, lpattern(solid) lwidth(*1.2) lcolor(orange))
			
		

graph export tochange.svg, replace
filefilter tochange.svg totransform.svg, from(`"stroke-width:5.24"') to(`"stroke-width:5.00; opacity:.65"') replace 
		
capture erase figure_A1.png
			
*Use inkscape to transform svg into png
!inkscape "`dir'/totransform.svg" --without-gui --export-dpi=1800 --export-png  "`dir'/figure_A1.png"                                                

window manage close graph

foreach file in `text'	tochange.svg totransform.svg	{
	cap erase `file'
}
exit

