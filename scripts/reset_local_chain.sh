#!/usr/bin/env bash
#
#   Removes data of test single-node network
#

set -eu
set -o pipefail

BIN_DIR="$(cd $(dirname $0) && pwd)"

. "$INSTALL_DIR/scripts/stop_local_chain.sh" &>/dev/null || true

rm -rf "$EOS_DIR"
