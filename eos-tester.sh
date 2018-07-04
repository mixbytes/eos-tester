#!/bin/bash

set -o pipefail
set +x

EOSDEV_INSTALL_DIR="/opt/eos-dev"

. $EOSDEV_INSTALL_DIR/scripts/_local_chain.incl.sh

init_containers() {
    docker pull eosio/eos-dev > /dev/null 2>&1
    echo "containers inited"
}

create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

init() {
    init_containers

    create_dir "test"
    create_dir "build"
    create_dir "contracts"
    create_dir "$EOS_DEV_DIR"
    create_dir "$LOGS_DIR"

    echo "" > $LOGS_FILE

    echo "$1" > $PROJECT_NAME_FILE
}

start_eos() {
    sudo $EOSDEV_INSTALL_DIR/scripts/reset_local_chain.sh
    $EOSDEV_INSTALL_DIR/scripts/start_local_chain.sh
}

stop_eos() {
    $EOSDEV_INSTALL_DIR/scripts/stop_local_chain.sh
    sudo $EOSDEV_INSTALL_DIR/scripts/reset_local_chain.sh
}


compile_contract() {
    $EOSDEV_INSTALL_DIR/scripts/compile.sh $1 build/
}

compile_contracts() {
    CONTRACTS_DIR="contracts"

    for f in $CONTRACTS_DIR/*.cpp; do
        if [ -e $f ]; then
            echo "compiling $f ...";
            compile_contract $f
        fi
    done
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
            contracts=',\n'"\"contract_$n\": 1"
        fi
    done

    cat package.json | sed -e "s/@contracts@/$contracts/" > .package.json
    cat .package.json > package.json

    rm .package.json
    cd ..
}

init_tests() {
    cp -r $EOSDEV_INSTALL_DIR/scripts/skeleton/test/* test/

    load_test_params

    cd test
    npm i >> $LOGS_FILE 2>&1
    cd ..

    echo "tests configured"
}

save_nodeos_logs() {
    docker logs --tail 1000 $(cat $NODEEOS_CID) &> $LOGS_DIR/nodeos.log &2>1
    echo "nodeos logs saved, can see here $LOGS_DIR/nodeos.log"
}

run_tests() {
    init_tests
    echo "running tests ..."
    cd test
    npm start
    save_nodeos_logs
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


if [ $1 == "init" ]; then
    if [ ! $2 ]; then
        die "usage: eos-dev init project_name"
    fi
    init $2
    init_tests
elif [ $1 == "test" ]; then
    check_init
    start_eos
    compile_contracts
    run_tests
    stop_eos
elif [ $1 == "compile" ]; then
    check_init
    compile_contracts
elif [ $1 == "clear" ]; then
    clear_all
else
    printf "usage: %s \\n   init       initalize eos-dev\\n   compile    compile contracts\\n   test       run tests\\n   clear      clear all data\\n"
    exit 1
fi
