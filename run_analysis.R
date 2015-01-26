library(plyr)
library(reshape2)

baseDir <- "~/Documents/Coursera/JHUDS/module-3"
dataDir <- "projectdata"
setwd(baseDir)

## Check to see if the source data exists in the working directory.
input <- paste(dataDir, "zip", sep=".")

if ( !file.exists(input) ) {
  destURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(destURL, destfile = input, method = "curl")
}

## Even if the source data does exists and is already extracted into the correct destination, extract a fresh copy of the source and overwrite any existing files in the source data directory.
if (file.exists(dataDir)) {
  setwd(paste(baseDir, dataDir, sep="/"))
  file.remove(list.files("."))
  setwd(baseDir)
}  

## Unzip the file into the project data folder and collapse all sub-directories; all files in sub-directories contain unique filenames, so there is no risk of a file from one sub-directory overwriting another
unzip(input, junkpaths=TRUE, exdir=dataDir)

## Read in the list of variables
variables <- read.csv(paste(dataDir, "features.txt", sep="/"), header=FALSE, sep="", col.names=c("colNumber", "name"), colClasses=c("integer", "character"), strip.white=TRUE)

## A simple function to merge the two test and the train datasets.  Error checking for file existence/access not implemented.
testtrainMerge <- function (test = "", train = "", colNames = "", dir = "~") {

  testData <- read.csv(paste(dir, test, sep="/"), header=FALSE, sep="", col.names=colNames, strip.white=TRUE)
  trainData <- read.csv(paste(dir, train, sep="/"), header=FALSE, sep="", col.names=colNames, strip.white=TRUE)
  
  merge(testData, trainData, all=TRUE)
}

## variables$name provides the column label for the dataset, so the data files subject_[test-train].txt and [XY]_[test-train].txt will be loaded.
subject <- testtrainMerge("subject_test.txt", "subject_train.txt", "subject", paste(baseDir, dataDir, sep="/"))
# activity <- testtrainMerge("y_test.txt", "y_train.txt", "activity", paste(baseDir, dataDir, sep="/"))
measurements <- testtrainMerge("X_test.txt", "X_train.txt", as.character(variables$colNumber), paste(baseDir, dataDir, sep="/"))

## For reasons completely unknown to me, y_test.txt and y_train.txt repeatedly failed during merge.  The result output was a vector containing 3645552 observations (every time), when it should have contained 10299 observation.
## Performing a manual merge (append) of the activity test and training data sets.
activity <- read.csv(paste(dataDir, "y_test.txt", sep="/"), header=FALSE, sep="", col.names=c("id"), strip.white=TRUE)
temp <- read.csv(paste(dataDir, "y_train.txt", sep="/"), header=FALSE, sep="", col.names=c("id"), strip.white=TRUE)

x <- nrow(activity)

for (y in seq_along(temp[, 1])) activity[x + y, 1] <- temp[y, 1]

## Import the activity labels to substitute for the integer values imported from y_test.txt and y_train.txt
activityLabels <- read.csv(paste(dataDir, "activity_labels.txt", sep="/"), header=FALSE, sep=" ", col.names=c("id", "activity"))

## Fortunately, the variables have a (mostly) consistent schema for their names, of "<base measurement name>-<statistic>-<axis indicator or other label>
## Because the structure will make it easy to find the only data needed for the project, which is the mean and standard deviation measurements.  They can be parsed by finding the string "mean()" or "std()" in the <statistic> position.
## Any measurements not following this convention were found to be neither a mean nor a standard deviation measurement, and therefore could be ultimately discarded.
## Variables with names containing "gravityMean" or "meanFreq()" are part of neither the mean nor standard deviation set of measurements.
variablesSplit <- strsplit(variables$name, "-")

## Now merge the names back into the variables data frame as three new columns; sapply is using a false function to methodically extract each vector element from the list.  The new columns created will be eventually discarded.
variables$mergedVar <- as.character(NA)
variables$measure <- as.character(NA)
variables$axis <- as.character(NA)
for (x in 1:3) variables[, x+2] <- sapply(variablesSplit, function(extract) extract[x])

## Drop everything but the mean and standard deviation measurements, by first selecting reducing to the entries in the 'variables' object and then selecting the same columns from the 'measurements' object
variablesTrimmed <- variables[variables$measure %in% c("mean()", "std()"), ]
measurementsTrimmed <- measurements[, variablesTrimmed$colNumber]

## Join the subject and activity data frames into the measurementsTrimmed data frame; use the text activity labels.
## Add a reference index, observation, for rejoining data later.
measurementsTrimmed$subject <- subject$subject
measurementsTrimmed$activity <- join(activity, activityLabels, by="id", type="left")$activity
measurementsTrimmed$observation <- seq(1, nrow(measurementsTrimmed))

## Reorganize the ordering of columns in measurementsTrimmed to move the last three columns to the first three.  Assign it back to original measurements object, which is no longer needed and taking up memory.
temp <- length(colnames(measurementsTrimmed))
measurements <- measurementsTrimmed[, c(temp, temp-2, temp-1, 1:(temp-3))]

## Use the variablesTrimmed data frame to create one big lookup table.  Because of the way R modified the column names while creating the measurements object (added an X to the beginning of each ), another lookup column needs to be added.
variablesTrimmed$sensor <- ifelse(grepl("Acc", variablesTrimmed$mergedVar), "acc", "gyro")
variablesTrimmed$signal.domain <- ifelse(substr(variablesTrimmed$mergedVar, 1, 1) == "f", "freq", "time")
variablesTrimmed$accel.source <- ifelse(grepl("Body", variablesTrimmed$mergedVar), "body", "grav")
variablesTrimmed$rate.type <- ifelse(grepl("Jerk", variablesTrimmed$mergedVar), "jerk", "acc")
variablesTrimmed$measure.type <- ifelse(grepl("Mag", variablesTrimmed$mergedVar), "mag", "vec")
variablesTrimmed$colName <- paste("X", as.character(variablesTrimmed$colNumber), sep="")

## Reorganize the ordering of the columns as such, and drop columns in the data frame no longer needed (colNumber, name, mergedVar).  Assign it back to original variables object, which is no longer needed and taking up memory.
temp <- c("colName", "signal.domain", "sensor", "accel.source", "rate.type", "measure.type", "axis", "measure")
variables <- variablesTrimmed[, temp]

## Convert the measurementsTrimmed into a column-oriented data frame by melting all the columns (except the first three), then joining variablesTrimmed to the dataset.
## This will be performed separately for the mean() and std() measurements, as a final join will place them as separate columns in the final data frame.
## At this point, the variablesTrimmed and measurementsTrimmed objects are no longer needed and still in memory.
measurementFrames <- c("mean", "std")
measurementList <- list(mean=NULL, std=NULL)

for (x in seq_along(measurementFrames)) {

  ## Preserve the first three columns of measurements, filter the variables list for only the mean measurements
  temp <- colnames(measurements)[1:3]
  variablesTrimmed <- variables[variables$measure==paste(measurementFrames[x], "()", sep=""), -8]
  measurementsTrimmed <- measurements[, c(temp, variablesTrimmed$colName)]
  
  ## Melt all the columns of measurements into one column of mean/std values, with each column header as the variable
  moltenMeasurements <- melt(measurementsTrimmed, id.vars=temp, measure.vars=variablesTrimmed$colName, variable.name = "colName", value.name=measurementFrames[x])
  
  ## Join on the column names in the measurement and variable objects to create a unified data set
  measurementsMerged <- join(moltenMeasurements, variablesTrimmed, by="colName", type="left")
  
  ## Column reorder, drop colName, store as data frames in a list of two elements, mean and std
  measurementList[[measurementFrames[x]]] <- measurementsMerged[, c(1:3, 6:11, 5)]
  
}

## Finally merge the mean and std data frames by joining on all other fields, and drop the observation field from the final data frame
temp <- colnames(measurementList[[1]])[1:9]
measurementsFinal <- join(measurementList[[1]], measurementList[[2]], by=temp, type="inner")
measurementsFinal <- measurementsFinal[, -1]

## Use ddply to average the mean and std measurements within each group of subjects, activities, and variables, then reduce the data frame to the unique values, and drop the original mean and std columns
output <- ddply(measurementsFinal, .(subject, activity, signal.domain, sensor, accel.source, rate.type, measure.type, axis), summarize, mean_avg=ave(mean), std_avg=ave(std))
output <- unique(output)

write.table(output, "run_analysis.txt", quote=FALSE, sep="\t", row.names=FALSE)
