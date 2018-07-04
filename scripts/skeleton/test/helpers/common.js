const Eos = require('eosjs');
const binaryen = require('binaryen');
const fs = require('fs');
const snake = require('to-snake-case');

module.exports = {
    randomName: () => {
        let name = "";
        let possible = "abcdefghijklmnopqrstuvwxyz";

        for (let i = 0; i < 12; i++)
            name += possible.charAt(Math.floor(Math.random() * possible.length));

        return name;
    },
    randomKeys: () => {
        let result = {};
        result.privateKey = Eos.modules.ecc.seedPrivate(Math.random().toString());
        result.publicKey = Eos.modules.ecc.privateToPublic(result.privateKey);
        return result;
    },
    eos: (keys = []) => {
        keys = [process.env.npm_package_config_eosioKey].concat(keys);

        return new Eos({
            httpEndpoint: process.env.npm_package_config_http,
            chainId: process.env.npm_package_config_chainId,
            binaryen: binaryen,
            keyProvider: keys,
            logger: {error: null},
        });
    },
    contract: (name) => {
        if (process.env['npm_package_config_contract_' + snake(name)] === undefined)
            return null;

        return {
            wast: fs.readFileSync('../build/' + name + '.wast'),
            abi: JSON.parse(fs.readFileSync('../build/' + name + '.abi')),
        }
    }
};