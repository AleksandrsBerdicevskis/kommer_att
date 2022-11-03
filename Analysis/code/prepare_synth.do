foreach training_type in  non_consecutive consecutive {
	use samples/all_sample_`training_type', clear
	
	              
	              
	*For attraction we generate a normally distributed variable that has 
	*mean = mean(attraction)-3*sd if outcome == 0
	*mean = mean(attraction)+3*sd if outcome == 1
	
	noisily di "Original"
	bysort outcome: sum attraction
	
	
	qui replace attraction = rnormal(1, 1) if outcome == 0
	qui replace attraction = rnormal(3, 1) if outcome == 1  
	
	noisily di "Artificial"
	bysort outcome: sum attraction
	
	save samples/synthetic_sample_`training_type', replace
	
	if "`training_type'" == "consecutive" {
				*For Arima analysis, prepare monthly corpora
				
				
				gen long datapoints = 1
		  	
				gcollapse outcome subject voice att_before att_after distance_to_att_words inf_length genre attraction (sum) datapoints, by(month test) fast
				
				tsset month, monthly
				
				
				order month
				
				compress
				save samples/synthetic_monthly_sample_`training_type', replace 
				export delimited using "samples/synthetic_monthly_sample.csv", delimiter(tab) replace
				}
}	
	
exit