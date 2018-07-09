# DONT run directly

# settings
LOGS_DIR="$EOS_DEV_DIR/.logs"
PROJECT_NAME_FILE="$EOS_DEV_DIR/.name"
LOGS_FILE="$EOS_DEV_DIR/.logs/logs"

NODEOS_CID="$EOS_DIR/.nodeos.cid"
KEOSD_CID="$EOS_DIR/.keosd.cid"

# dont change - workaround for cleos bug https://github.com/EOSIO/eos/issues/3145#issuecomment-395951751https://github.com/EOSIO/eos/issues/3145#issuecomment-395951751
EOS_NETWORK="host"
EOS_DOCKER='docker'

# computed - dont touch

NODEOS_DATA="$EOS_DIR/nodeos"
KEOSD_DATA="$EOS_DIR/keosd"
MOUNT_DIR="$EOS_DIR/docker-mount"

EOS_PUB_KEY_FILE="$EOS_DIR/pubkey"




die() {
    echo $*
    exit 1
}
