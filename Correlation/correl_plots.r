dataset <- read.csv("correl_transposed.tsv",sep="\t",header=TRUE)
par(mfrow = c(2,4))
barplot(dataset$time,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="time",names.arg=dataset$corpus,las=2)
barplot(dataset$attraction,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="attraction",names.arg=dataset$corpus,las=2)
barplot(dataset$distance_to_att_words,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="distance",names.arg=dataset$corpus,las=2)
barplot(dataset$inf_length,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="inf. length",names.arg=dataset$corpus,las=2)
barplot(dataset$subject,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="subject",names.arg=dataset$corpus,las=2)
barplot(dataset$att_before,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="att before",names.arg=dataset$corpus,las=2)
barplot(dataset$att_after,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="att after",names.arg=dataset$corpus,las=2)
barplot(dataset$voice,ylim=c(-0.1,0.3),col=c("red","green","brown","blue","yellow","gray","orange"),main="voice",names.arg=dataset$corpus,las=2)



