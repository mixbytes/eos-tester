#!/usr/bin/env bash
#
#   Stops test single-node network
#

set -o pipefail

$EOS_DOCKER stop $(cat $KEOSD_CID) >> $LOGS_FILE 2>&1
if [ ! $? ]; then
    echo "keosd stoped"
fi

$EOS_DOCKER stop $(cat $NODEOS_CID) >> $LOGS_FILE 2>&1
if [ ! $? ]; then
    echo "nodeos stoped"
fi
