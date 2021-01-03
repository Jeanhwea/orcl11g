#!/usr/bin/env bash

set -e
source /assets/colorecho
source ~/.bashrc

ALERT_LOG="$ORACLE_BASE/diag/rdbms/ora11g/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
LSNER_LOG="$ORACLE_BASE/diag/tnslsnr/$ORACLE_SID/listener/trace/listener.log"
PFILE_ORA=$ORACLE_HOME/dbs/init$ORACLE_SID.ora


# monitor $logfile
monitor() {
  tail -F -n 0 $1 | while read line; do echo -e "$(date '+%F %T') $2: $line"; done
}


dbtrap() {
  trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
  trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}


dbstart() {
  echo_yellow "Starting listener..."
  monitor $LSNER_LOG listener &
  lsnrctl start | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  MON_LSNR_PID=$!
  echo_yellow "Starting database..."
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
  echo_yellow "Database does not exist. Creating database..."
  date "+%F %T"
  monitor $ALERT_LOG alertlog &
  MON_ALERT_PID=$!
  monitor $LSNER_LOG listener &
  # lsnrctl start | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  # MON_LSNR_PID=$!
  echo "START DBCA"
  dbca -silent -createDatabase -responseFile /assets/dbca.rsp
  echo_green "Database created."
  change_dpdump_dir
  touch $PFILE_ORA
  dbtrap
  kill $MON_ALERT_PID
  # wait $MON_ALERT_PID
}


dbshut() {
  ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
  echo_yellow "Shutting down the database..." && \
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
  echo_yellow "Shutting down listener..."
  lsnrctl stop | while read line; do echo -e "$(date '+%F %T') lsnrctl: $line"; done
  kill $MON_ALERT_PID $MON_LSNR_PID
  exit 0
}


change_dpdump_dir () {
  echo_green "Changind dpdump dir to /u01/app/dpdump"
  sqlplus / as sysdba <<-EOF |
    CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/u01/app/dpdump';
    COMMIT;
    EXIT 0
EOF
  while read line; do echo -e "$(date '+%F %T') sqlplus: $line"; done
}


echo_yellow "Checking shared memory..."
df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo_red "Shared memory is not mounted."
if [ ! -f $PFILE_ORA ]; then
  dbcreate;
fi
dbstart
