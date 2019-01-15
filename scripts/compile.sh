#!/usr/bin/env bash
#
#   Compiles contract
#

set -o pipefail

[[ $# -gt 1 ]] || die "usage: $0 contract_cpp output_dir [--with-abi]"

CONTRACT_CPP="$1"
OUTPUT_DIR="$(cd "$2" && pwd)"

[[ -n "$CONTRACT_CPP" && -n "$OUTPUT_DIR" ]] || die "usage: $0 contract_cpp output_dir"

CONTRACT_DIR="$(cd "$(dirname "$CONTRACT_CPP")" && pwd)"
CONTRACT_NAME="$(basename "$CONTRACT_CPP" | sed -e 's/\.cpp$//')"

CONTRACT_CPP_BASENAME="$(basename "$CONTRACT_CPP")"
CONTRACT_HPP_BASENAME="$CONTRACT_NAME.hpp"


$EOS_DOCKER run --rm -v "$CONTRACT_DIR":/input -v "$OUTPUT_DIR":/output \
    "$EOS_IMAGE" /opt/eosio/tools/eosiocpp \
    -o /output/"$CONTRACT_NAME.wast" /input/"$CONTRACT_CPP_BASENAME" >$LOGS_DIR/compile.log 2>&1

if grep -q -i "ERROR" $LOGS_DIR/compile.log; then
    die "compile wast error, see $LOGS_DIR/compile.log for more details";
fi

if [[ $3 == "--with-abi" ]]; then
    ABI_SOURCE="$CONTRACT_CPP_BASENAME"

    $EOS_DOCKER run --rm -v "$CONTRACT_DIR":/input -v "$OUTPUT_DIR":/output \
        "$EOS_IMAGE" /opt/eosio/tools/eosiocpp \
        -g /output/"$CONTRACT_NAME.abi" /input/"$ABI_SOURCE" >$LOGS_DIR/compile.log 2>&1

    if grep -q -i "ERROR" $LOGS_DIR/compile.log; then
        die "generate abi error, see $LOGS_DIR/compile.log for more details";
    fi
fi
