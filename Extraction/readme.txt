This folder contains the scripts which are necessary to reproduce data extraction and annotation.

In order to run the scripts you would need to install Ruby and the 'json' gem. The scripts were tested using Ruby version 2.6.3p62 on Windows 10. 
Known compatilibity issues: if you use version 3.x, you may have to replace the deprecated URI.escape method.

Run reproduce.rb to reproduce the whole process (NB: long and somewhat unstable process which will download several gigabytes of data), see comments inside the script to reproduce separate steps.
Consider also that if you extract data from Språkbanken's corpora, you may get different results, since corpora are not static: they can be updated, cleaned up etc. In addition, the ids of the observations won't match the ones in our dataset.