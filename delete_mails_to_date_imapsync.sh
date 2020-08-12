#!/bin/bash

#===================================================================
#     FILE: delete_mails_to_date_imapsync.sh
#     USAGE: ./delete_mails_to_date_imapsync.sh
#
#     DESCRIPTION: This is a simple script that deletes mails in batches from a specific date from a specific mailbox using imapsync.
#     The idea is that you can delete mails from certain date backwards, e.g. today is 06-01-2019, you want to delete mails in batches of 5 days
#     from 01-01-2019 to 01-01-2018 and you want to keep mails from 01-01-2019 and newer. You can do that by using imapsync and setting the source
#     and destination to the same server and same mailbox. In order to achieve what is described in this example you will need to set:
#     days=(1 5 10 15 20 25 31)
#     months=('Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec')
#     year='2018'
#     The script will then delete mails backwards - from the oldest to the latest date specified, e.g. from 01 Jan 2018 until 31 Dec, 2018
#     REQUIREMENTS: Adjust user1, user2, password1, password2, host1 and host2 to your actual values. Source and destination must be the same.
#     BUGS: ---
#     NOTES: ---
#     AUTHOR: Valentin Dzhorov
#     ORGANIZATION: Delta.BG
#     CREATED: 12-08-2020
#     REVISION: 0.1  
#  ---
#===================================================================

# Change days in whatever iteration period you want. Example 1 5 10 15 20 25 31. 
# This will delete mails in batches of five days (except the last which is 6 days).
days=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)
# Months which are to be cleaned.
months=('Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec')
# Year which is to be cleaned.
year='2019'
log=deletedmails.log
user1='user@domain.com'
user2='user@domain.com'
password1='password'
password2='password'
host1='host'
host2='host'

# Log cleanup beforehand
echo "" > $log 

for month in ${months[@]}; do
  for day in ${days[@]}; do
    echo "---------------- BEGIN AT `date` ----------------" >> $log
    # Run imapsync command
    imapsync --host1 $host1 --timeout1 0 --user1 $user1 --password1 $password1 --delete1 --ssl1 --search "SENTBEFORE $day-$month-$year" --host2 $host2 --user2 $user2 --password2 $password2 --ssl2 --timeout2 0 --nofoldersizes --nofoldersizesatend --noexpungeaftereach
    if [[ "$?" == 0 ]]; then
      echo "Succesfully deleted messages older than $day-$month-2019 at `date`" >> $log
    else
      # If all else fails retry 3 more times and log entry, then rerun command
      for retry in {1..3}; do
      echo "Error occured on $day-$month-2019, retrying $retry times" >> $log
      imapsync --host1 $host1 --timeout1 0 --user1 $user1 --password1 $password1 --delete1 --ssl1 --search "SENTBEFORE $day-$month-$year" --host2 $host2 --user2 $user2 --password2 $password2 --ssl2 --timeout2 0 --nofoldersizes --nofoldersizesatend --noexpungeaftereach
        if [[ "$?" == 0 ]]; then
        echo "Succesfully deleted messages older than $day-$month-2019 at `date` after retry" >> $log
        continue
        fi
      done
    fi
    echo "---------------- END AT `date` ----------------" >> $log
  done
done
