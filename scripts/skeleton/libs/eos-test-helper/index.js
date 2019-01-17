const Eos = require('eosjs');
const fs = require('fs');

const config = {
    chainId: null,
    expireInSeconds: 60,
    broadcast: true,
    verbose: false,
    sign: true
};

const NODE_URL = process.env.NODE_URL || 'http://localhost:8888';
const DEFAULT_KEY = process.env.DEFAULT_KEY || '5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3';
const SYSTEM_ACCOUNT_NAME = process.env.SYSTEM_ACCOUNT_NAME || 'eosio';

const system_account = {
    name: SYSTEM_ACCOUNT_NAME,
    private_key: DEFAULT_KEY,
};


function api(keys = []) {
    return Eos({...config, keyProvider: keys.concat(DEFAULT_KEY), httpEndpoint: NODE_URL});
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
    let system_contract = await api([deployer.private_key]).contract(SYSTEM_ACCOUNT_NAME);

    await system_contract.setcode(deployer.name, 0, 0, contract.wasm);
    await system_contract.setabi(deployer.name, contract.abi);
}


async function new_account(new_account, creator = system_account) {
    let system_contract = await api([creator.private_key]).contract(SYSTEM_ACCOUNT_NAME);

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