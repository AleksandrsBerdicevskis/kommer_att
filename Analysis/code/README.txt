Please use the do_file _master.do for replication
*-------------------*
Data management, logistic models and visualizations were coded in Stata/MP 14.2 2-core on a Linux server (CentOS 7.9.2009) with 756GB of available RAM
*-------------------*
ARIMAs were trained in the Jupyter/Python 3.6.8: TSarima_exog.ipynb
*-------------------*
To process visualizations, Inkscape 0.92.2 was used
*-------------------*
Be careful with "call_logistic_models.do", as it serves as a 'master instance' and starts 216 instances of Stata where the actual models for different specifications are fitted. 
Once an instance has finished it‘s job, it sends back the relevant info to the master instance and exits itself. 
So unless you have a powerful computing server with a least several hundreds of available RAM, please be careful to avoid crashing your system/server. 
*-------------------*
contact: koplenig@ids-mannheim.de
*-------------------*