import "@nomiclabs/hardhat-etherscan";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import dotenv from "dotenv";

dotenv.config();

const INCO_RPC_URL = process.env.INCO_RPC_URL;
const F1A4A = process.env.PRIVATE_KEY;
const ROOTSTALKER_PRIVATE = process.env.ROOTSTALKER_PRIVATE;

module.exports = {
  defaultNetwork: "inco",
  networks: {
    hardhat: {
      chainId: 31337,
      allowBlocksWithSameTimestamp: true,
      gasPrice: "auto",
      initialBaseFeePerGas: 0,
      allowUnlimitedContractSize: true,
      // mining: {
      //   auto: false,
      // },
    },
    inco: {
      url: INCO_RPC_URL || "",
      accounts: [F1A4A, ROOTSTALKER_PRIVATE],
      chainId: 9090,
      timeout: 200000, // Increase the timeout value
    },
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    bob: {
      default: 1,
    },
    cat: {
      default: 2,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          evmVersion: "cancun",
          optimizer: {
            enabled: true,
            runs: 100,
            details: {
              yul: true, //https://github.com/ethereum/solidity/issues/11638#issuecomment-1101524130 (added this so that coverage works)
            },
          },
          //viaIR: true,
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    showTimeSpent: true,
    token: "ETH",
  },
  mocha: {
    timeout: 30000, // 500 seconds max for running tests
    parallel: true,
  },
};
