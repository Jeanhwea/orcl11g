#!/usr/bin/env bash
set -e

source ~/.bashrc

ALERT_LOG="$ORACLE_BASE/diag/rdbms/ora11g/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
LSNER_LOG="$ORACLE_BASE/diag/tnslsnr/${HOSTNAME//.*/}/listener/trace/listener.log"
PFILE_ORA=$ORACLE_HOME/dbs/init$ORACLE_SID.ora


# monitor $logfile
monitor() {
  tail -F -n 0 $1 | while read line; do echo -e "$(date '+%F %T') $2: $line"; done
}


dbtrap() {
  trap "echo 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
  trap "echo 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}


dbstart() {
  echo "Starting listener..."
  monitor $LSNER_LOG listener &
  lsnrctl start | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  MON_LSNR_PID=$!
  echo "Starting database..."
  dbtrap
  monitor $ALERT_LOG alertlog &
  MON_ALERT_PID=$!
  sqlplus / as sysdba <<-EOF |
    PROMPT Starting with pfile='$PFILE_ORA' ...
    STARTUP;
    ALTER SYSTEM REGISTER;
    EXIT 0
EOF
  while read line; do echo -e "$(date '+%F %T') sqlplus: $line"; done
  wait $MON_ALERT_PID
}


dbcreate() {
  echo "Database does not exist. Creating database..."
  date "+%F %T"
  monitor $ALERT_LOG alertlog &
  MON_ALERT_PID=$!
  monitor $LSNER_LOG listener &
  # lsnrctl start | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  # MON_LSNR_PID=$!
  echo "START DBCA"
  dbca -silent -createDatabase -responseFile /assets/dbca.rsp
  echo "Database created."
  change_dpdump_dir
  touch $PFILE_ORA
  dbtrap
  kill $MON_ALERT_PID
  # wait $MON_ALERT_PID
}


dbshut() {
  ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
  echo "Shutting down the database..." && \
  sqlplus / as sysdba <<-EOF |
    SET ECHO ON
    SHUTDOWN IMMEDIATE;
    EXIT 0
EOF
  while read line; do echo -e "$(date '+%F %T') sqlplus: $line"; done
}


dbclose() {
  trap '' SIGINT SIGTERM
  dbshut
  echo "Shutting down listener..."
  lsnrctl stop | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  kill $MON_ALERT_PID $MON_LSNR_PID
  exit 0
}


change_dpdump_dir () {
  echo "Changing dpdump dir to /u01/app/dpdump"
  sqlplus / as sysdba <<-EOF |
    CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/u01/app/dpdump';
    COMMIT;
    EXIT 0
EOF
  while read line; do echo -e "$(date '+%F %T') sqlplus: $line"; done
}


echo "Checking shared memory..."
df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo "Shared memory is not mounted."
if [ ! -f $PFILE_ORA ]; then
  dbcreate;
fi
dbstart
