const { dynamicAddress } = require("@dgma/hardhat-sol-bundler");
const { VerifyPlugin } = require("@dgma/hardhat-sol-bundler/plugins/Verify");

const config = {
  LedgerLib: {},
  Ledger: {
    options: {
      libs: {
        LedgerLib: dynamicAddress("LedgerLib"),
      },
    },
  },
};

module.exports = {
  hardhat: {
    config,
  },
  localhost: { lockFile: "./local.deployment-lock.json", config },
  arbitrumSepolia: {
    lockFile: "./deployment-lock.json",
    verify: true,
    plugins: [VerifyPlugin],
    config,
  },
};
