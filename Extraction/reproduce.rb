#extract the data from Språkbanken's corpora. This is a long process which will download several gigabytes of data. It is possible that it will crash due to some unforeseen exception on the server side. In this case, you will have to restart it manually and tweak the script so that it does not download those data which it has already collected. In short: do not run this step unless you absolutely must. 

system "ruby api_extract_observations.rb da-all"
system "ruby api_extract_observations gp-all"
system "ruby api_extract_observations svt-all"
system "ruby api_extract_observations bloggmix-all"
system "ruby api_extract_observations twitter-all"
system "ruby api_extract_observations familjeliv-all"
system "ruby api_extract_observations flashback-all"

#process the downloaded jsons into convenient tsvs
system "ruby process_extracted_observations.rb da,gp,svt,bloggmix,twitter,familjeliv,flashback"

#merge the tsvs, remove some columns that are not used in the study, transform some predictors
system "ruby merge.rb"