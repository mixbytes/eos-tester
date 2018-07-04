#!/usr/bin/env bash
#
#   Stops test single-node network
#

set -o pipefail

BIN_DIR="$(cd $(dirname $0) && pwd)"

. "$BIN_DIR/_local_chain.incl.sh"


$EOS_DOCKER stop keosd >> $LOGS_FILE 2>&1
echo "keosd stoped"

$EOS_DOCKER stop nodeos >> $LOGS_FILE 2>&1
echo "nodeos stoped"

if [[ "$EOS_NETWORK" != "host" ]]; then
    $EOS_DOCKER network rm "$EOS_NETWORK" >> $LOGS_FILE 2>&1
fi

