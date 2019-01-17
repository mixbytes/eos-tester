#!/usr/bin/env bash
#
#   Removes data of test single-node network
#

set -eu
set -o pipefail

. "$INSTALL_DIR/scripts/stop_local_chain.sh" &>/dev/null || true

rm -rf "$EOS_DIR"
