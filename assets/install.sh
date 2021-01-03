#!/usr/bin/env bash
set -e

trap "echo '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

if [ ! -d "/install/database" ]; then
  echo "Installation files not found. Unzip installation files into mounted(/install) folder"
  exit 1
fi

echo "Installing Oracle Database 11g ..."

su oracle -c "/install/database/runInstaller -silent -ignorePrereq -waitforcompletion -responseFile /assets/db_install.rsp"

echo "Executing root scripts"
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/11.2.0/dbhome_1/root.sh

echo "Database installed."
