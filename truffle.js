require('babel-register');
const PrivateKeyProvider = require("truffle-privatekey-provider");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      gas: 4707806,
      network_id: '*' // Match any network id
    },
    rinkeby: {
      provider() {
        return new PrivateKeyProvider(process.env.OWNER_PRIVATE_KEY, "https://rinkeby.infura.io/")
      },
      gas: 4700000,
      network_id: 4
    },
  }
};
