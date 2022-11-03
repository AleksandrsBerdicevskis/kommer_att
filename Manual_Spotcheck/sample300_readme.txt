status_error: 1 if the "status" (automatic) is not equal to "correct_status" (manual)
subject_presence_error: 1 if subject_present (automatic) is wrong (manual). Not annotated for when correct_status == noise.
other_errors: 1 if any other column where the header is bold (status + predictors + lemma) contains an error
att_before and att_before contain the number of "att" resp. before or after "kommer (att)". In the article, this feature is binarized (whether there is at least one "att")
