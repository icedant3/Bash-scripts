#!/bin/bash +x

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

BACKUP_HOST="IP"
BACKUP_PORT="port"
BACKUP_USER="user"

#DST_PATH="/backup/`hostname`"

DST_PATH_DAILY="/backup/$(hostname)/daily"
DST_PATH_MONTHLY="/backup/$(hostname)/monthly"
DST_PATH_MONTHLY16="/backup/$(hostname)/monthly16"

today=$(date +%d-%m-%Y)
#today=`date +16-%m-%Y`
firstday=$(date +01-%m-%Y)
day16=$(date +16-%m-%Y)
BACKUP_DIRS="/home/backup/$today"
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

RSYNC_OPTS="-aqxAHSX --delete --delete-excluded --numeric-ids"
mkdir -p "/home/backup/$today"
mysql -N -e 'show databases' | while read dbname;
do
  if [ $dbname == "information_schema" ] || [ $dbname == "performance_schema" ]; then
    continue
  fi
  log_info "Dumping $dbname"
  /usr/bin/mysqldump --skip-lock-tables --quick --routines --events --triggers $dbname >"/home/backup/$today/$dbname.sql"
  check_ret_val "Error dumping the $dbname database"
done
if [ $today = $firstday ]; then #check if the first day of the month, if yes, then make a backup to the folder monthly
  #  ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "mkdir -p $DST_PATH_MONTHLY/$today"
  /usr/bin/rsync $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_MONTHLY/
  if [ $? = 0 ]; then
    echo "Monthly database backup $today successfully created".
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_MONTHLY/$today ]"; then #if there is today's backup
      #delete the old backup on the first day of the first month
      rm -rf /home/backup/*
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY/$LAST_MONTH_START"
      echo "Old monthly database backup $LAST_MONTH_START deleted from $DST_PATH_MONTHLY"
    fi
    log_info "Backup completed"
  else
    echo "Backup error"
    log_info "Backup error"
  fi

elif [ $today = $day16 ]; then
  /usr/bin/rsync $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_MONTHLY16/
  if [ $? = 0 ]; then
    echo "Monthly 16 backup $today successfully created".
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_MONTHLY16/$today ]"; then #if there is today's backup
      #delete the old backup on the first day of the first month
      rm -rf /home/backup/*
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_MONTHLY16/$LAST_MONTH_16"
      echo "Old monthly database backup $LAST_MONTH_16 deleted from $DST_PATH_MONTHLY16"
    fi
    log_info "Backup completed"
  else
    echo "Backup error"
    log_info "Backup error"
  fi

else
  /usr/bin/rsync $RSYNC_OPTS -e "ssh -p $BACKUP_PORT" $BACKUP_DIRS $BACKUP_USER@$BACKUP_HOST:$DST_PATH_DAILY/
  if [ $? = 0 ]; then
    echo "Daily database backup $today successfully created".
    if ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "[ -d $DST_PATH_DAILY/$today ]"; then #if there is today's backup
	if [ $day5 == $firstday ] || [ $day5 == $day16 ]; then
	
	:
	
     elif [ $day5 != $firstday ] || [ $day5 != $day16 ]; then
	
      #delete the old backup on the first day of the first month
      rm -rf /home/backup/*
      ssh -p $BACKUP_PORT $BACKUP_USER@$BACKUP_HOST "rm -rf $DST_PATH_DAILY/$day5"
      echo "Old daily database backup $day5 deleted from $DST_PATH_DAILY"
    fi
    log_info "Backup completed"
  else
    echo "Backup error"
    log_info "Backup error"
  fi
fi
fi
