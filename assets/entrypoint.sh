#!/usr/bin/env bash

set -e
source /assets/colorecho

mount -o remount,size=4G /dev/shm

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
  echo_yellow "Database is not installed. Installing..."
  /assets/install.sh
fi


su oracle -c "/assets/startup.sh"
