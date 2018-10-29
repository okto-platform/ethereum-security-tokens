var HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = 'mnemonic';

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*"
        },
        ropsten: {
            provider: function() {
                return new HDWalletProvider(MNEMONIC, "https://ropsten.infura.io/v3/e8b4c0d8975c49299aeb6befc5d46a95")
            },
            network_id: 3,
            gas: 8000000
        }
    }
};
