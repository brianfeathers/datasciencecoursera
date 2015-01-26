# Getting and Cleaning Data Course Project

## Codebook

### Column 1:  subject
* integer
* range = [1:30]
* Description:  numbered test subject in study

### Column 2:  activity
* factor
* levels = [WALKING; WALKING_UPSTAIRS; WALKING_DOWNSTAIRS; SITTING; STANDING; LAYING]
* Description:  activity in which the subject was participating at the time the measurement was taken

### Column 3:  signal.domain
* factor
* levels = [freq; time]
* Description:  variable identifying whether the measurement was obtained by calculating variables from either the time (time) or frequency (freq) domain

### Colume 4:  sensor
* factor
* levels = [acc; gyro]
* Description:  variable identifying which of the phone's built-in sensors was the source of the measurement - the accelerometer (acc) or gyroscope (gyro).  Measurements taken from the accelerometer signal are in units = m/(sec^2).  Measurements taken from the gyroscope are in units = radians/sec

### Column 5:  accel.source
* factor
* levels = [body; grav]
* Description:  variable identifying the component of the sensor acceleration signal - the body motion (body) or gravity (grav)

### Column 6:  rate.type
* factor
* levels = [acc; jerk]
* Description:  variable identifying the whether the measurement is for the original acceleration or the calculated rate of change of acceleration, the jerk.  Measurements calculating the jerk require units different from the default specified in "sensor"; the accelerometer signal units = m/(sec^3), and the gyroscope signal units = radians/(sec^2).

### Column 6:  measure.type
* factor
* levels = [mag; vec]
* Description:  variable identifying is a vector component measurement (vec) or a scalar magnitude measurement (mag) of the vector components.

### Column 7:  axis
* factor
* levels = [X; Y; Z; <NA>]
* Description:  variable identifying is the vector component measured.  Measurements of type "mag" (in measure.type) do not have vector components and will have a level of NA.

### Column 8:  mean_avg
* numeric
* Description:  average of the mean measurements from the original dataset.

### Column 9:  std_avg
* numeric
* Description:  average of the standard deviation measurements from the original dataset.

## Description of the script
The script, run_analysis.R, is heavily documented (almost self-describing) on the particulars of each step taken.  The comments are copied verbatim and provided here:
* Check to see if the source data exists in the working directory.
* Even if the source data does exists and is already extracted into the correct destination, extract a fresh copy of the source and overwrite any existing files in the source data directory.
* Unzip the file into the project data folder and collapse all sub-directories; all files in sub-directories contain unique filenames, so there is no risk of a file from one sub-directory overwriting another.
* Read in the list of variables.
* A simple function to merge the two test and the train datasets.  Error checking for file existence/access not implemented.
* For reasons completely unknown to me, y_test.txt and y_train.txt repeatedly failed during merge.  The result output was a vector containing 3645552 observations (every time), when it should have contained 10299 observation.  Performing a manual merge (append) of the activity test and training data sets.
* Import the activity labels to substitute for the integer values imported from y_test.txt and y_train.txt
* Fortunately, the variables have a (mostly) consistent schema for their names, of "<base measurement name>-<statistic>-<axis indicator or other label>.  Because the structure will make it easy to find the only data needed for the project, which is the mean and standard deviation measurements.  They can be parsed by finding the string "mean()" or "std()" in the <statistic> position.  Any measurements not following this convention were found to be neither a mean nor a standard deviation measurement, and therefore could be ultimately discarded.  Variables with names containing "gravityMean" or "meanFreq()" are part of neither the mean nor standard deviation set of measurements.
* Now merge the names back into the variables data frame as three new columns; sapply is using a false function to methodically extract each vector element from the list.  The new columns created will be eventually discarded.
* Drop everything but the mean and standard deviation measurements, by first selecting reducing to the entries in the 'variables' object and then selecting the same columns from the 'measurements' object.
* Join the subject and activity data frames into the measurementsTrimmed data frame; use the text activity labels.  Add a reference index, observation, for rejoining data later.
* Reorganize the ordering of columns in measurementsTrimmed to move the last three columns to the first three.  Assign it back to original measurements object, which is no longer needed and taking up memory.
* Use the variablesTrimmed data frame to create one big lookup table.  Because of the way R modified the column names while creating the measurements object (added an X to the beginning of each ), another lookup column needs to be added.
* Reorganize the ordering of the columns as such, and drop columns in the data frame no longer needed (colNumber, name, mergedVar).  Assign it back to original variables object, which is no longer needed and taking up memory.
* Convert the measurementsTrimmed into a column-oriented data frame by melting all the columns (except the first three), then joining variablesTrimmed to the dataset.  This will be performed separately for the mean() and std() measurements, as a final join will place them as separate columns in the final data frame.  At this point, the variablesTrimmed and measurementsTrimmed objects are no longer needed and still in memory.
* Finally merge the mean and std data frames by joining on all other fields, and drop the observation field from the final data frame.
* Use ddply to average the mean and std measurements within each group of subjects, activities, and variables, then reduce the data frame to the unique values, and drop the original mean and std columns.