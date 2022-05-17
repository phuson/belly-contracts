const dotenv = require('dotenv');
dotenv.config({ path: __dirname + '/.env' });

require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-gas-reporter');
require('solidity-coverage');

require('./tasks/verify');
require('./tasks/getContract');

const { task, ethers } = require('hardhat/config');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// first account's private key of the local chain for testing
const TEST_ACCOUNTS = [
  '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
];

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'hardhat',
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  abiExporter: {
    path: './src/artifacts', // add ABI to check in
    clear: true,
    flat: false,
    spacing: 2,
  },
  mocha: {
    timeout: 5000000,
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    hardhat: {
      gasPrice: 875000000,
      initialBaseFeePerGas: 0,
      // https://hardhat.org/guides/mainnet-forking.html
      // forking: {
      //   url:
      //     'https://eth-mainnet.alchemyapi.io/v2/6nq-D8GelA2u5x7ZHmFnl67Fkn_QeIj_',
      //   blockNumber: 12033280,
      // },
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_APP_ID}`,
      accounts: TEST_ACCOUNTS,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_APP_ID}`,
      accounts: TEST_ACCOUNTS,
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_APP_ID}`,
      accounts: TEST_ACCOUNTS,
    },
    'polygon-mainnet': {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_APP_ID}`,
      accounts: TEST_ACCOUNTS,
    },
    'polygon-mumbai': {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_APP_ID}`,
      accounts: TEST_ACCOUNTS,
    },
  },
  solidity: {
    version: '0.8.13',
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: 'none',
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};
