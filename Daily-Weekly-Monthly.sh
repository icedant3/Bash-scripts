#!/bin/bash


# Log an info message to syslog
log_info() {
  logger -t backup -p syslog.info $1
}

# Log an error to syslog and exit
log_error() {
  logger -t backup -p syslog.error $1
  exit 1
}

# Check the exit code of a command
check_ret_val() {
  if [ $? -ne 0 ]; then
    log_error $1
  fi
}



BACKUP_HOST="185.181.230.122"
BACKUP_PORT="22684"
BACKUP_USER="backupmivosmart"
BACKUP_DIRS="/var/log /home"


DST_PATH_DAILY="/backup/$(hostname)/daily"
DST_PATH_MONTHLY="/backup/$(hostname)/monthly"
DST_PATH_MONTHLY16="/backup/$(hostname)/monthly16"

today=$(date +%d-%m-%Y)
firstday=$(date +01-%m-%Y)
day16=$(date +16-%m-%Y)

day1=$(date +%d-%m-%Y --date="-1 day")
day2=$(date +%d-%m-%Y --date="-2 day")
day3=$(date +%d-%m-%Y --date="-3 day")
day4=$(date +%d-%m-%Y --date="-4 day")
day5=$(date +%d-%m-%Y --date="-5 day")

TODAY=$(date '+%F') # or whatever YYYY-MM-DD you need

THIS_MONTH_16=$(date -d "$TODAY" '+%Y-%m-16')
LAST_MONTH_16=$(date -d "$THIS_MONTH_16 -1 month" '+%d-%m-%Y')

THIS_MONTH_START=$(date -d "$TODAY" '+%Y-%m-01')
LAST_MONTH_START=$(date -d "$THIS_MONTH_START -1 month" '+%d-%m-%Y')


RSYNC_OPTS="-aqxAHSX --delete --delete-excluded --numeric-ids --exclude cache/*"


#Creating a backup

if [ $today = $firstday ]; then #check if the first day of the month, if yes, then make a backup to the folder monthly
  ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "mkdir -p $DST_PATH_MONTHLY/$today"

  log_info "Starting rsync"
  echo "Backup started"
  /usr/bin/rsync $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_MONTHLY/$today
  if [ $? = 0 ]; then
    log_info "Backup completed"
    echo "Monthly backup $today successfully created"
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_MONTHLY/$today ]"; then #if there is today's backup
      #delete the old backup on the first day of the first month
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY/$LAST_MONTH_START"
      echo "Old monthly backup $LAST_MONTH_START deleted from $DST_PATH_MONTHLY"
    fi
  else
    log_info "Error backup"
    ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY/$today"
    echo 'Weekly backup not created, action aborted'
  fi

elif
  [ $today = $day16 ]
then
  ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "mkdir -p $DST_PATH_MONTHLY16/$today"

  log_info "Starting rsync"
  echo "Backup started"
  /usr/bin/rsync $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_MONTHLY16/$today
  if [ $? = 0 ]; then
    log_info "Backup completed"
    echo "Monthly 16 backup $today successfully created"
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_MONTHLY16/$today ]"; then #if there is today's backup
      #delete the old backup on the first day of the first month
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY16/$LAST_MONTH_16"
      echo "Old monthly 16 backup $LAST_MONTH_16 deleted from $DST_PATH_MONTHLY16"
    fi
  else
    log_info "Error backup"
    ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY16/$today"
    echo 'Weekly 16 backup not created, action aborted'
  fi

else
  #if today is not the first day of the month, make a backup to the daily folder
  ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "mkdir -p $DST_PATH_DAILY/$today"

  log_info "Starting rsync"
  echo "Backup started"
  /usr/bin/rsync --exclude '/home/smart/web/smart.md/public_html/image' $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_DAILY/$today
  if [ $? = 0 ]; then
    log_info "Backup completed"
    echo "Weekly backup $today successfully created"  
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_DAILY/$today ]"; then #if there is today's backup
       if [ $day5 == $firstday ] || [ $day5 == $day16 ]; then
      
         :                                                                                   #skip the deletion if today is 1 or 16
           elif [ $day5 != $firstday ] || [ $day5 != $day16 ]; then
    #delete old backup 5 days ago
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_DAILY/$day5"
      echo "Old weekly backup $day5 deleted from $DST_PATH_DAILY"
    fi
  else
    log_info "Error backup"
    ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_DAILY/$today"
    echo 'Daily backup not created, action aborted'
  fi
fi

fi
