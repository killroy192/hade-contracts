const config = require("dotenv").config();

require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-toolbox");
require("@dgma/hardhat-sol-bundler");
require("./tasks");
const { ZeroHash } = require("ethers");
const deployments = require("./deployment.config");

if (config.error) {
  console.error(config.error);
}

const deployerAccounts = [config?.parsed?.PRIVATE_KEY || ZeroHash];

const DEFAULT_RPC = "https:random.com";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [{ version: "0.8.20" }],
    metadata: {
      appendCBOR: false,
    },
  },
  paths: {
    sources: "src",
    tests: "test",
  },
  networks: {
    hardhat: {
      deployment: deployments.hardhat,
    },
    localhost: {
      deployment: deployments.localhost,
    },
    arbitrumSepolia: {
      url: config?.parsed?.ARBITRUM_SEPOLIA_RPC || DEFAULT_RPC,
      accounts: deployerAccounts,
      deployment: deployments.arbitrumSepolia,
    },
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: config?.parsed?.ARBISCAN_API_KEY,
    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia-explorer.arbitrum.io",
        },
      },
    ],
  },
};
