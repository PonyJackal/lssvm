const Web3 = require("web3");
const web3 = new Web3();
const HDWalletProvider = require('@truffle/hdwallet-provider');

const fs = require('fs');
let mnemonic;
try {
  mnemonic = fs.readFileSync("../../../Documents/seed.txt", "utf8").slice(0, -1);
} catch (err) {
  console.log(err);
}

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
     development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 9545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
      gas: "6721975"
     },
    // Another network with more advanced options...
    // advanced: {
    // port: 8777,             // Custom port
    // network_id: 1342,       // Custom network
    // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
    // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    // from: <address>,        // Account to send txs from (default: accounts[0])
    // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },
    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    ropsten: {
      provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/eb5ba991ba924ec5b80fd85423fd901f`),
      network_id: 3,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    live: {
      provider: () => new HDWalletProvider(mnemonic, `https://mainnet.infura.io/v3/eb5ba991ba924ec5b80fd85423fd901f`),
      network_id: 1,
      gasPrice: web3.utils.toWei('140', 'gwei'),
      skipDryRun: true
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/eb5ba991ba924ec5b80fd85423fd901f`),
      network_id: 4,
      skipDryRun: true,
      gasPrice: web3.utils.toWei('2', 'gwei'),
    },
    matic: {
      provider: () => new HDWalletProvider(mnemonic, 'https://polygon-rpc.com/'),
      network_id: 137,
      skipDryRun: true,
      gasPrice: web3.utils.toWei('10', 'gwei'),
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.13",
      settings: {    
       optimizer: {
         enabled: true,
         runs: 200,
         details: {
          cse: true,
          constantOptimizer: true,
          yul: true,
          deduplicate: true
         }
       },
      }
    },
  },
  plugins: ["solidity-coverage"]
};