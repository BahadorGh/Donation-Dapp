require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
const path = require('path');
require('dotenv').config({path: path.resolve(__dirname, './.env')});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    sepolia : {
      url: `${process.env.SEPOLIA_RPC}/${process.env.PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY]
    },
    hardhat: {
    }
  },
  etherscan: {
    apiKey: process.env.EtherScan_API,
  },
  
};
