#!/usr/bin/env bash

set -e
source /assets/colorecho

SHM_SIZE=4g
echo "tmpfs /dev/shm tmpfs defaults,size=$SHM_SIZE 0 0" >> /etc/fstab
mount -o remount,size=$SHM_SIZE /dev/shm

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
  echo_yellow "Database is not installed. Installing..."
  /assets/install.sh
fi


su oracle -c "/assets/startup.sh"
