#!/usr/bin/env bash
#
#   Starts test single-node network
#

set -o pipefail

BIN_DIR="$(cd $(dirname $0) && pwd)"

mkdir -p "$EOS_DIR"
mkdir -p "$NODEOS_DATA"
mkdir -p "$KEOSD_DATA"

set +x

#if [[ "$EOS_NETWORK" != "host" ]]; then
#    $EOS_DOCKER network create "$EOS_NETWORK" >> $LOGS_FILE 2>&1
#fi

$EOS_DOCKER run --rm -d -v "$NODEOS_DATA":/data \
    -p "$NODEOS_PORT":"8888/tcp" \
    -p "$NODEOS_PORT":"8888/udp" \
    "$EOS_IMAGE" /opt/eosio/bin/nodeos \
    -d /data \
    --http-server-address=0.0.0.0:"8888" \
    --http-validate-host=false \
    -e -p eosio --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin --contracts-console \
    > $NODEOS_CID 2>&1

echo "nodeos started"

$EOS_DOCKER run --rm -d -v "$KEOSD_DATA":/data \
    -p "$KEOSD_PORT":"9999/tcp" \
    -p "$KEOSD_PORT":"9999/udp" \
    "$EOS_IMAGE" /opt/eosio/bin/keosd \
    -d /data \
    --http-server-address=0.0.0.0:"9999" \
    --http-validate-host=false \
    --unlock-timeout=1000000000 \
    > $KEOSD_CID 2>&1

echo "keosd started"


. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
wallet create >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3 >> $LOGS_FILE 2>&1

echo 'EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV' > "$EOS_PUB_KEY_FILE"
echo "wallet created"

#. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
#set code eosio /contracts/eosio.system/eosio.system.wast >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
set abi eosio /contracts/eosio.system/eosio.system.abi >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
create account eosio eosio.token EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV \
EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
set code eosio.token /contracts/eosio.token/eosio.token.wast >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
set abi eosio.token /contracts/eosio.token/eosio.token.abi >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
push action eosio.token create '[ "eosio", "1000000000.0000 EOS"]' -p eosio.token >> $LOGS_FILE 2>&1

. "$INSTALL_DIR/scripts/cleos" -u "http://127.0.0.1:$NODEOS_PORT" --wallet-url "http://127.0.0.1:$KEOSD_PORT" \
push action eosio.token issue '[ "eosio", "1000000000.0000 EOS", "init" ]' -p eosio >> $LOGS_FILE 2>&1

echo "EOS token created"
