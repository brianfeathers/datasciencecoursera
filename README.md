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
* Description:  variable identifying is the vector component measured.  Measurements of type "mag" (in measure.type) do not have vector components and will have a level of <NA>.

### Column 8:  mean_avg
* numeric
* Description:  average of the mean measurements from the original dataset.

### Column 9:  std_avg
* numeric
* Description:  average of the standard deviation measurements from the original dataset.