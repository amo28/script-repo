#!/bin/bash
#Checks the a log for the most recent entry's timestamp and outputs logic checks against it.

#Create the datediff function
#Use  with: datediff "$date1" "$date2"
#Outputs numerical value in number of days
datediff() {
        d1=$(date -d "$1" +%s)
        d2=$(date -d "$2" +%s)
        echo $(( ($d1 - $d2) / 86400 ))
}

#Create the timediff function
#Use with: timediff "$time1" "$time2"
#Outputs numerical value in number of seconds
timediff() {
        t1=$(date -u -d "$1" +"%s")
        t2=$(date -u -d "$2" +"%s")
        echo $(( ($t1 - $t2) ))
}

HOST_NAME=$1
#Set date to output in same format that the log's timestamp does.
current_date="$(date +"%m/%d/%Y")"
current_time="$(date +"%T")"

#Configure amount of time in seconds that should trigger an alert. 
#If the last entry is older than this value, Zabbix will send an alert email.
time_compare=1200

#smbclient command to pull the log and then read the last line.
last_entry="$(smbclient -U [USER] //$HOST_NAME/[SHARE] [PASSWORD] -c 'more [FILENAME] /dev/fd/1' 2>/dev/null | tail -1)"

#Loop to parse $LAST_UPLOAD into variables. IFS=' ,' sets the delimters to space and comma.
#""read uploaddate uploadtime rest"" means to set the first variable to uploaddate, the second
#to uploadtime, and remaining variables to 'rest'. We just need the first two.
#The last part <<< $last_entry pipes that variable into the read command as the input.
IFS=' ,'  read uploaddate uploadtime rest <<< "$last_entry"

#Find the delta values to compare. Uses the datediff and timediff functions created above to give
#delta values in seconds, which are then added together to get a single date/time value in seconds.
date_delta=$(( ($(datediff $current_date $uploaddate) * 86400) ))
time_delta="$(timediff $current_time $uploadtime)"
compare_delta=$(( ($date_delta + $time_delta) ))

#Alert logic if compare_delta is greater than upload_time_compare
if (( $compare_delta > $time_compare )); then
#Delta is greater than the time_compare value. Something is wrong. Echo 1.
        echo "1"
else
#Delta is less than time_compare value. Everything is good. Echo 0.
        echo "0"
fi
exit
