do prepare_raw  /* prepare datasets for each maincorpus*/

do prepare_samples /* prepare yearly samples */

do prepare_synth  /* prepare additional corpus where influence of two variables is strong inflated */

do call_logistic_models.do /* calls logistic_models.do*/

do plot_logistic_models 1 /* plot for consecutive split */
do plot_logistic_models 2 /* plot for non_consecutive split */ 

do plot_logistic_proportions /* figure 2 */

/* ARIMAs are trained in the Jupyter/Python: TSarima_exog.ipynb */

do plot_ARIMA full_sample /* plot ARIMA results for full sample forecast */
do plot_ARIMA one_step 		/* plot ARIMA results for one step ahead forecast */

do plot_synthetic /* fiugre 6 */

exit

contact: koplenig@ids-mannheim.de