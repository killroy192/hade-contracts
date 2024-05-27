const { parseUnits } = require("ethers");
const { dynamicAddress } = require("@dgma/hardhat-sol-bundler");
// const { VerifyPlugin } = require("@dgma/hardhat-sol-bundler/plugins/Verify");

const libsConfig = {
  BTypeLib: {},
  LinkedListLibrary: {},
  TokenMath: {},
};

const sharedContracts = {
  ExposureToken: {
    contractName: "SharesToken",
    args: ["ExposureToken", "ET"],
  },
  HedgeToken: {
    contractName: "SharesToken",
    args: ["HedgeToken", "HT"],
  },
  Registry: {
    options: {
      libs: {
        LinkedListLibrary: dynamicAddress("LinkedListLibrary"),
      },
    },
  },
};

const externalContracts = {
  linkETHUSDFeed: {
    arbitrumSepolia: "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
    // todo: use mock instead
    hardhat: "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
    localhost: "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
  },
};

const getConfig = (chain) => ({
  ...libsConfig,
  ...sharedContracts,
  Oracle: {
    options: {
      libs: {
        TokenMath: dynamicAddress("TokenMath"),
      },
    },
    args: [externalContracts.linkETHUSDFeed[chain]],
  },
  Balancer: {
    options: {
      libs: {
        BTypeLib: dynamicAddress("BTypeLib"),
      },
    },
    args: [
      (_, ctx) => ({
        exposureToken: ctx.ExposureToken.address,
        hedgeToken: ctx.HedgeToken.address,
        oracle: ctx.Oracle.address,
        multiplier: parseUnits("1.001", 11),
        rebalanceExposurePrice: parseUnits("3500", 16),
      }),
    ],
  },
});

module.exports = {
  hardhat: {
    config: getConfig("hardhat"),
  },
  localhost: { lockFile: "./local.deployment-lock.json", config: getConfig("localhost") },
  arbitrumSepolia: {
    lockFile: "./deployment-lock.json",
    // verify: true,
    // plugins: [VerifyPlugin],
    config: getConfig("arbitrumSepolia"),
  },
};
