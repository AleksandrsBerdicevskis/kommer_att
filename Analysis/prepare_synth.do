foreach training_type in  non_consecutive consecutive {
	use samples/all_sample_`training_type', clear
	
	set seed 376929              
	              
	
	noisily di "Original"
	bysort outcome: sum attraction
	
	gen random = runiform()
	*For attraction increase each value of attraction by .2 if outcome == 0 and random >.5
	qui replace attraction = attraction + .2 if outcome == 0 & random >.5
	drop random
	

	

	noisily di "Artificial"
	bysort outcome: sum attraction
	
	save samples/synthetic_sample_`training_type', replace
	
	if "`training_type'" == "consecutive" {
				*For Arima analysis, prepare monthly corpora
				
				
				gen long datapoints = 1
		  	
				gcollapse outcome subject voice att_before att_after att_interaction distance_to_att_words inf_length genre attraction (sum) datapoints, by(month test) fast
				
				tsset month, monthly
				
				
				order month
				
				compress
				save samples/synthetic_monthly_sample_`training_type', replace 
				export delimited using "samples/synthetic_monthly_sample.csv", delimiter(tab) replace
				}
}	
	
exit