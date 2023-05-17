1. The folder "Extraction" contains all the tools that are necessary to reproduce the automatic extraction and annotation of data.
It is not recommended to reproduce this step. First, you would have to go through a slow and unstable process of downloading several gigabytes of data. Second, since the source corpora have been updated after we performed the data extraction, the resulting dataset will no be identical to the one we used in the study. It will contain more observations, and their ids will not fully match the ids in our dataset. 

The full dataset that we used can be found at http://demo.spraakdata.gu.se/sasha/kommer_att_predictors_all.zip

2. The folder "Manual_spotcheck" contains the manually checked sample.

3. The folder "Correlation" contains the scripts that are necessary to reproduce the visualization in Section 3.5.

4. The folder "Analysis" contains the scripts that are necessary to perform the statistical analysis.

The balanced samples that were extracted for analysis can be found at http://demo.spraakdata.gu.se/sasha/samples.zip.

5. The folder "Balanced_Accuracy" contains the script and the data which are necessary to reproduce the additional analysis in Appendix C.

6. The folder "Predictions" contains the actual predictions of the logistic models (for the micro-level, Q1), both for consecutive and random splits. Use the "global_id" column to match the predictions with the other parts of the dataset.

Contact: aleksandrs.berdicevskis@gu.se