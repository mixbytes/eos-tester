#!/usr/bin/env bash
#
#   Stops test single-node network
#

set -o pipefail

$EOS_DOCKER stop $(cat $KEOSD_CID) >> $LOGS_FILE 2>&1
echo "keosd stoped"

$EOS_DOCKER stop $(cat $NODEOS_CID) >> $LOGS_FILE 2>&1
echo "nodeos stoped"

if [[ "$EOS_NETWORK" != "host" ]]; then
    $EOS_DOCKER network rm "$EOS_NETWORK" >> $LOGS_FILE 2>&1
fi

