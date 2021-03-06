## load libraries
## if you do not have these installed use: install.packages("ggplot2"), for example, to downoad the library
library(ggplot2)
library(RColorBrewer)
library(data.table)
library(dplyr)
library(readr)
library(stringr)

## set working directory
setwd("C:/Users/pawlusm/Desktop")

## read in the file
act2 <- read_csv("actions_eval_july16.csv")   ## create csv using KL-action reports.sql (##act2)

month_year <- "july16"

#### if you want to use this exact script with no edits then you will need the following column headers:

#[1] "coreid"       "RE_Val"       "AffTtl"       "Total_Giving" "goLast"       "actDesc"     
#[7] "actDate"      "category"     "mode"         "actText"     




#### make cuts to put real estate values into buckets


## check the range of values

#act2$RE_Val <- as.integer(act2$RE_Val)  ## not needed right now
range(act2$RE_Val, na.rm = TRUE)

## convert all missing values to zero

#act2[is.na(act2)]   <- 0  ## also not needed

## put real estate values into $100,000 buckets
act2$re_grp <- cut(act2$RE_Val, breaks = seq(-1, 999999, by = 100000), label=FALSE)

## code the outliers (all zeroes are coded as zeroes and those over $1M are coded as 11)
act2$re_grp[act2$RE_Val==0] <- 0
act2$re_grp[is.na(act2$re_grp)]   <- 11

## convert rating to factor and then reorder factor levels
act2$re_grp <- as.factor(as.character(act2$re_grp))
act2<- within(act2, re_grp <- reorder(re_grp, as.numeric(as.character(re_grp))))

## plot results (faceted bar plot)

jpeg(paste0(month_year,"_actions_by_re.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

ggplot(data=act2) +
  geom_bar(mapping=aes(x=re_grp, fill=goLast)) + 
  facet_grid(goLast~.) +
  theme_bw() + 
  labs(title="Actions by RE")

dev.off()

#### make cuts to put total giving values into buckets


## check the range of values
range(act2$Total_Giving)  

## put total giving values into $10,000 buckets
act2$tg_grp<- cut(act2$Total_Giving, breaks = seq(0, 100000, by = 10000), label=FALSE)

## code the outliers (all zeroes are coded as zeroes and those over $100,000 are coded as 11)
act2$tg_grp[act2$Total_Giving==0] <- 0
act2$tg_grp[is.na(act2$tg_grp)]   <- 11

## convert rating to factor and then reorder factor levels
act2$tg_grp <- as.factor(as.character(act2$tg_grp))
act2<- within(act2, tg_grp <- reorder(tg_grp, as.numeric(as.character(tg_grp))))

## plot results

jpeg(paste0(month_year,"_actions_by_giving.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

ggplot(data=act2) +
  geom_bar(mapping=aes(x=tg_grp, fill=goLast)) + 
  facet_grid(goLast~.) +
  theme_bw() +
  labs(title="Actions by Total Giving")

dev.off()


#### histogram by affinity without buckets  
## (may add a 2-pass bucketing in a future iteration -- only for those greater than 10)


act2$AffTtl <- as.factor(as.character(act2$AffTtl ))
act2<- within(act2, AffTtl <- reorder(AffTtl, as.numeric(as.character(AffTtl))))

## plot results

jpeg(paste0(month_year,"_actions_by_affinity.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

ggplot(data=act2[ which(act2$AffTtl!=0),]) +
  geom_bar(mapping=aes(x=AffTtl, fill=goLast)) + 
  facet_grid(goLast~.) +
  theme_bw() + 
  labs(title="Actions by Affinity")

dev.off()

#### get the mean word count


## make a column of all zeroes (this is where your word count will go)
act2$wrdc <- rep(0,nrow(act2))

## make another column for concatenated strings and fill it in with all "x"s for now.
## this is needed if you have multiple fields that are used for narrative text in contact reports
## this column will hold the combined text
act2$conc <- rep("x",nrow(act2))

## concatenate description and comment fields which are the two text fields in Millennium that are used
for (i in 1:nrow(act2)) {
  act2[i,17] <- paste(act2[i,8], act2[i,12], sep = " ")  # change columns conc gets two text fields
}

## word count for each
## this goes row by row and splits the text field by spaces (" ") seperating each word
## it then counts the number of individual words
for (i in 1:nrow(act2)) {
  y <- act2[i,17]
  z <- str_split(y, " ")
  act2[i,16] <- length(z[[1]])  
}

## this creates a data frame of mean values based on the word counts for each gift officer
mm <-  act2 %>% 
       group_by(goLast) %>% 
       summarise(mwrds = mean(wrdc, na.rm = TRUE)) 

## bar plot of average word count

jpeg(paste0(month_year,"_word_count_by_gift_officer.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

ggplot(mm, aes(x = goLast, y = mwrds)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x=element_text(angle=45,hjust=1,vjust=1))

dev.off()

#### plot giving by category

jpeg(paste0(month_year,"_cats_by_gift_officer.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

ggplot(act2, aes(goLast, fill=category)) + 
  geom_bar() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1,vjust=1))

dev.off()

#### plot giving by mode

jpeg(paste0(month_year,"_methods_by_gift_officer.jpeg"), width = 10.5, height = 8, units = 'in', res = 300)

qplot(factor(goLast), data=act2, geom="bar", fill=factor(mode)) + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1,vjust=1))

dev.off()

#### make a word cloud


## load in additional libraries
library(tm)
library(SnowballC)
library(wordcloud)

#### global word cloud  (for all gift officers collectively)

## set up the image window  (this might only be necessary if reseting after doing the by gift officer view below)
par(mfrow = c(1,1))

##### word clouds are new to me so my comments below are what I think is happening

## create a corpus of word objects from the text column 
actCorpus <- Corpus(VectorSource(act2$conc))

## map the words to a plain text doc
actCorpus <- tm_map(actCorpus, PlainTextDocument)

## this removes punctuation and common words like "the", "it", etc. (I believe)
actCorpus <- tm_map(actCorpus, removePunctuation)
actCorpus <- tm_map(actCorpus, stripWhitespace)
actCorpus <- tm_map(actCorpus, tolower)
actCorpus <- tm_map(actCorpus, removeNumbers)
actCorpus <- tm_map(actCorpus, removeWords, stopwords())
actCorpus <- tm_map(actCorpus, removeWords, "josh")
actCorpus <- tm_map(actCorpus, removeWords, "kathryn")

## this will look to find root words and match them i.e.: go, goes, going will all get grouped as one word element
actCorpus <- tm_map(actCorpus, stemDocument)

## create word cloud
wordcloud(actCorpus,
          scale = c(3,.1),
          max.words = 25, 
          min.freq = 5,
          random.order = FALSE,
          colors = brewer.pal(9, 'Blues')[4:9]
          )


#### a different method

#In tm package, the documents are managed by a structure called Corpus
myCorpus = Corpus(VectorSource(actCorpus))

#Create a term-document matrix from a corpus
tdm = TermDocumentMatrix(myCorpus,control = list(removePunctuation = TRUE,stopwords = c("josh", "kathryn", "jim", "steven", "jon", "mike", "jen", "greg", "bennie", "tom", "health", "north", "gvsu", "grand", "summer", "lot", "valley", "daughter", "traverse", stopwords("english")), removeNumbers = TRUE, tolower = TRUE))

#Convert as matrix
m = as.matrix(tdm)

#Get word counts in decreasing order
word_freqs = sort(rowSums(m), decreasing=TRUE) 

#Create data frame with words and their frequencies
dm = data.frame(word=names(word_freqs), freq=word_freqs)

#Plot wordcloud
jpeg("example_word_cloud.jpeg", width = 10.5, height = 8, units = 'in', res = 300)

wordcloud(dm$word, dm$freq, random.order=FALSE, min.freq = 7, colors=brewer.pal(8, "Dark2"))

dev.off()


#### individual word cloud  (for all gift officers seperately)



## create a factor list for each gift officer last name
f <- as.factor(unique(act2$goLast))

## for each name in the factor list create a word cloud
for (i in 1:max(as.numeric(f))){
  actCorpus <- Corpus(VectorSource(act2$conc[act2$goLast==f[i]]))
  
  actCorpus <- tm_map(actCorpus, PlainTextDocument)
  
  actCorpus <- tm_map(actCorpus, removePunctuation)
  actCorpus <- tm_map(actCorpus, removeWords, stopwords('english'))
  
  actCorpus <- tm_map(actCorpus, stemDocument)
  
  ## this formats the image frame so the gift officer name is on top and word cloud below
  layout(matrix(c(1, 2), nrow=2), heights=c(1, 4))
  par(mar=rep(0, 4))
  plot.new()
  
  ## this sets a text element to the gift officer last name
  text(x=0.5, y=0.5, f[i])
  
  ## create a word cloud including a title which will list the gift officers name
  ## this creates a seperate image for each gift officer
  wordcloud(actCorpus,
            scale = c(3,.1),
            max.words = 25, 
            min.freq = 5,
            random.order = FALSE,
            colors = brewer.pal(9, 'Blues')[4:9],
            main = "Title"
  )
}


#### sentiment analysis

## load library
library(syuzhet)

#### global emotion chart (for all gift officers collectively)

## put text data in its own vector
ocomm <- act2$conc

## get the emotional data by checking words against emotion-based taxonomy
d<-get_nrc_sentiment(ocomm)

## transpose the data frame (make columns into rows and rows into columns)
td<-data.frame(t(d))

## get a numerical sum for each emotion based on the count from each action
td_new <- data.frame(rowSums(td[2:ncol(td)]))

## rename the first column heading for td_new
names(td_new)[1] <- "count"

## column bind the rownames with the emotion names for td_new as a column called sentiment
td_new <- cbind("sentiment" = rownames(td_new), td_new)

## remove row names since they are duplicated now
rownames(td_new) <- NULL

## td_new2 contains the first 8 values which are the different emotions
td_new2<-td_new[1:8,]

## td_new3 contains the last 2 rows which are the positive or negative sentiment
td_new3<-td_new[9:10,]

#plot emotions
qplot(sentiment, data=td_new2, weight=count, geom="histogram",fill=sentiment)+ggtitle("Emotional Sentiment")
#plot +/- sentiment
qplot(sentiment, data=td_new3, weight=count, geom="histogram",fill=sentiment)+ggtitle("Postive/Negative Sentiment")



#### split emotion chart by gift officer


#f <- as.factor(unique(act2$goLast))  # this is only need if you didn't already do it above

## follow the steps as above for the first gift officer in the factor list shown subseted like: [act2$goLast==f[1]]
ocomm <- act2$conc[act2$goLast==f[1]]
d<-get_nrc_sentiment(ocomm)
td<-data.frame(t(d))

td_new <- data.frame(rowSums(td[2:ncol(td)]))

names(td_new)[1] <- "count"
td_new <- cbind("sentiment" = rownames(td_new), td_new)
rownames(td_new) <- NULL

## make a new column with the gift officer's name
td_new$goLast <- f[1]

## get percentage/proporation of visits that fall into each emotional category
q <- as.numeric(td_new[[2]][1:8])/sum(as.numeric(td_new[[2]][1:8]))
## get percentage/proporation of visits that fall into each +/- category
w <- as.numeric(td_new[[2]][9:10])/sum(as.numeric(td_new[[2]][9:10]))
## put vector q and vector w together in a combined vector e
e <- append(q,w)

## add the column containing percentage to the td_new data frame
td_new$percent <- e

## copy td_new to td_all so that you can iterate over td_new for each gift officer and add it to td_all
td_all <- td_new

## for loop to cycle through each gift officer
for (i in 2:max(as.numeric(f))){

## the first portion of this is the same as above
ocomm <- act2$conc[act2$goLast==f[i]]
d<-get_nrc_sentiment(ocomm)
td<-data.frame(t(d))

td_new <- data.frame(rowSums(td[2:ncol(td)]))

names(td_new)[1] <- "count"
td_new <- cbind("sentiment" = rownames(td_new), td_new)
rownames(td_new) <- NULL
td_new$goLast <- f[i]

q <- as.numeric(td_new[[2]][1:8])/sum(as.numeric(td_new[[2]][1:8]))
w <- as.numeric(td_new[[2]][9:10])/sum(as.numeric(td_new[[2]][9:10]))
e <- append(q,w)

td_new$percent <- e

## in this step we row bind each new td_new data from for each gift officer to td_all which has data for all gift officers
td_all <- rbind(td_new,td_all)
}

## create a vector of numbers to subset the emotional rows
a <- 10 - 2:9

for (i in 2:max(as.numeric(f))){
  b <- (i*10) - 2:9
  a <- append(a,b)
}

## create a vector of numbers to subset the +/- rows
k <- 10 - 0:1

for (i in 2:max(as.numeric(f))){
  l <- (i*10) - 0:1
  k <- append(l,k)
}

## plot emotion chart (using 'a' from above which has the row index number for emotions)
qplot(sentiment, data=td_all[a,], weight=percent, geom="histogram",fill=sentiment)+ 
  facet_grid(goLast~.)+
  ggtitle("Emotional Sentiment")
## plot +/- chart (using 'k' from above which has the row index number for +/-)
qplot(sentiment, data=td_all[k,], weight=percent, geom="histogram",fill=sentiment)+
  facet_grid(goLast~.)+
  ggtitle("Postive/Negative Sentiment")


## if you notice any unusual trends you can check comments for any person using the snippet below

#act2$conc[act2$goLast=="(name)"]
