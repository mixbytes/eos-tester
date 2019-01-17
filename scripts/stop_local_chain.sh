#!/usr/bin/env bash
#
#   Stops test single-node network
#

set -o pipefail

$EOS_DOCKER stop $(cat $KEOSD_CID) >> $LOGS_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "keosd stoped"
else
    echo "Error: can't stop keods, check logs"
fi


$EOS_DOCKER stop $(cat $NODEOS_CID) >> $LOGS_FILE 2>&1
if [ $? -eq 0 ]; then
    echo "nodeos stoped"
else
    echo "Error: can't stop nodeos, check logs"
fi
