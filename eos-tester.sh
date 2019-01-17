#!/bin/bash

set -o pipefail
set +x

INSTALL_DIR="/opt/eos-tester"

EOS_DEV_DIR="$PWD/.eos-dev"
EOS_DIR="$EOS_DEV_DIR"
NODEOS_PORT=3413
KEOSD_PORT=3414

. $INSTALL_DIR/scripts/_local_chain.incl.sh

init_containers() {
    docker pull $EOS_IMAGE
    echo "containers inited"
}

create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

init() {
    if [[ $NETWORK == "dev" ]]; then
        init_containers
    fi

    create_dir "test"
    create_dir "build"
    create_dir "contracts"
    create_dir "$EOS_DEV_DIR"
    create_dir "$LOGS_DIR"

    echo "" > $LOGS_FILE

    echo "$1" > $PROJECT_NAME_FILE
}

start_eos() {
    . $INSTALL_DIR/scripts/start_local_chain.sh
}

stop_eos() {
    . "$INSTALL_DIR/scripts/stop_local_chain.sh"
}

reset_eos() {
    . "$INSTALL_DIR/scripts/reset_local_chain.sh"
}

error() {
    stop_eos
    die $1
}

compile_contract() {
    if ! . $INSTALL_DIR/scripts/compile.sh $1 build/ $2 ; then
        error
    fi
}

compile_contracts() {
    CONTRACTS_DIR="contracts"

    if [[ $# -gt 0 ]] && [[ $1 != "--with-abi" ]]; then
        if [ -e "$PWD/$1" ]; then
            echo "compiling "$PWD/$1" ...";
            compile_contract "$PWD/$1" $2
        else
            echo "contract $1 not found";
        fi
    else
        for f in $CONTRACTS_DIR/*.cpp; do
            if [ -e $f ]; then
                echo "compiling $f ...";
                compile_contract $f $1
            fi
        done
    fi
}

load_test_params() {
    chain_id=$(curl -s -i http://localhost:$NODEOS_PORT/v1/chain/get_info | grep -Po '"chain_id":".*?"' | awk -F"\"" '{print $4}')
    http="http:\/\/localhost:$NODEOS_PORT"
    name=$( cat $PROJECT_NAME_FILE )

    cd test

    cat package.json | sed -e "s/@name@/$name-tests/" > .package.json
    cat .package.json > package.json

    cat package.json | sed -e "s/@chain_id@/$chain_id/" > .package.json
    cat .package.json > package.json

    cat package.json | sed -e "s/@http@/$http/" > .package.json
    cat .package.json > package.json

    contracts=""
    for f in ../contracts/*.cpp; do
        if [ -e $f ]; then
            n=$( echo $f | sed -e "s/.cpp//" | awk -F"/" '{print $3}' )
            contracts=$contracts',\n'"\"contract_$n\": 1"
        fi
    done

    cat package.json | sed -e "s/@contracts@/$contracts/" > .package.json
    cat .package.json > package.json

    rm .package.json
    cd ..
}

init_tests() {
    cp -r $INSTALL_DIR/scripts/skeleton/* .

    load_test_params

    cd test
    npm i >> $LOGS_FILE 2>&1
    cd ..

    echo "tests configured"
}

save_nodeos_logs() {
    docker logs --tail 1000 $(cat $NODEOS_CID) &> nodeos.log &2>1
    echo "nodeos logs saved, can see here $LOGS_DIR/nodeos.log"
}

run_tests() {
    init_tests
    echo "running tests ..."
    cd test

    TEST_DIR=$PWD NETWORK=$NETWORK npm start || true

    if [[ $NETWORK == "dev" ]]; then
        save_nodeos_logs
    fi

    cd ..
}

check_init() {
    if [ ! -d $EOS_DEV_DIR ]; then
        die "first run 'eos-dev init' in current directory"
    fi
}

clear_all() {
    rm -rf $EOS_DEV_DIR
    echo "all data cleared"
}

com_node_start() {
    if [ $# -ge 3 ]; then
        NODEOS_PORT=$1
        KEOSD_PORT=$2
        EOS_DIR=$3
        EOS_DEV_DIR=$EOS_DIR

        . $INSTALL_DIR/scripts/_local_chain.incl.sh
        create_dir "$LOGS_DIR"

        start_eos
    else
        die "usage: eos-tester node start <nodeos port> <keosd port> <eos data dir>"
    fi
}

com_node_stop() {
    if [ $# -ge 1 ]; then
        EOS_DIR=$1
        EOS_DEV_DIR=$EOS_DIR
        . $INSTALL_DIR/scripts/_local_chain.incl.sh

        stop_eos
    else
        die "usage: eos-tester node stop <eos data dir>"
    fi
}

com_node() {
    if [ $# -lt 1 ]; then
        die "usage: eos-tester node <start|stop>"
    elif [ $1 == "start" ]; then
        shift
        com_node_start $@
    elif [ $1 == "stop" ]; then
        shift
        com_node_stop $@
    else
        die "usage: eos-tester node <start|stop>"
    fi
}

com_test_init() {
    init_tests
}

com_test_run() {
    init

    if [ $# -eq 0 ]; then
        NETWORK="dev"
    else
        NETWORK=$1
    fi

    if [[ $NETWORK == "dev" ]]; then
        start_eos
    fi

    run_tests

    if [[ $NETWORK == "dev" ]]; then
        stop_eos
        reset_eos
    fi
}

com_test() {
    if [ $# -lt 1 ]; then
        die "usage: eos-tester test <init|run> [network]"
    elif [ $1 == "run" ]; then
        shift
        com_test_run $@
    elif [ $1 == "init" ]; then
        shift
        com_test_init $@
    else
        die "usage: eos-tester test <init|run>"
    fi
}

com_compile() {
    check_init
    compile_contracts $@
}

com_clear() {
    clear_all
}

com_init() {
    if [ $# -lt 1 ]; then
        die "usage: eos-tester init <project_name>"
    fi

    init
    init_tests
}

com_cleos() {
    . $INSTALL_DIR/scripts/_local_chain.incl.sh

    . $INSTALL_DIR/scripts/cleos $@
}

usage() {
    printf "Usage:\\n \
                init       initalize eos-dev\\n \
                compile    compile contracts\\n \
                test       test commands\\n \
                clear      clear all data\\n \
                node       start, stop custom node\\n"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
elif [ $1 == "init" ]; then
    shift
    com_init $@
elif [ $1 == "test" ]; then
    shift
    com_test $@
elif [ $1 == "compile" ]; then
    shift
    com_compile $@
elif [ $1 == "clear" ]; then
    shift
    com_clear $@
elif [ $1 == "node" ]; then
    shift
    com_node $@
elif [ $1 == "cleos" ]; then
    shift
    com_cleos $@
else
    usage
fi
