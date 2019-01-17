const Eos = require('eosjs');
const fs = require('fs');

const config = {
    chainId: null,
    expireInSeconds: 60,
    broadcast: true,
    verbose: false,
    sign: true
};

const TEST_DIR = process.env.TEST_DIR;

const test_conf = require(TEST_DIR + '/config.json');
const NETWORK_NAME = process.env.NETWORK || 'dev';

const network = test_conf.network[NETWORK_NAME];

const system_account = {
    name: network.system_account,
    private_key: network.default_key || '',
};


function api(keys = []) {
    keys = network.default_key ? keys.concat(network.default_key) : keys;
    return Eos({...config, keyProvider: keys, httpEndpoint: network.url});
}


function random_name() {
    let name = "";
    let possible = "abcdefghijklmnopqrstuvwxyz";

    for (let i = 0; i < 12; i++)
        name += possible.charAt(Math.floor(Math.random() * possible.length));

    return name;
}


async function random_keys() {
    let result = {};
    result.private_key = await Eos.modules.ecc.unsafeRandomKey();
    result.public_key = await Eos.modules.ecc.privateToPublic(result.private_key);
    return result;
}


function load_contract(dir, name) {
    let contract = {};

    try {
        contract.wasm = fs.readFileSync(dir + '/' + name + '.wasm');
        contract.abi = JSON.parse(fs.readFileSync(dir + '/' + name + '.abi'));
    }
    catch (e) {
        throw new Error(`Contract load error: ${e.message}`);
    }

    return contract;
}


async function deploy(deployer, contract) {
    let system_contract = await api([deployer.private_key]).contract(network.system_account);

    await system_contract.setcode(deployer.name, 0, 0, contract.wasm);
    await system_contract.setabi(deployer.name, contract.abi);
}


async function new_account(new_account, creator = system_account) {
    let system_contract = await api([creator.private_key]).contract(network.system_account);

    await system_contract.newaccount({
        creator: creator.name,
        name: new_account.name,
        owner: new_account.public_key,
        active: new_account.public_key
    }, {
        authorization: creator.name,
    });
}


module.exports = {
    api: api,
    random_name: random_name,
    random_keys: random_keys,
    load_contract: load_contract,
    deploy: deploy,
    new_account: new_account,
};
