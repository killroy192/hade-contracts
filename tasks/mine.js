const { task } = require("hardhat/config");

const MINE = "mine";

task(MINE, "Enable 2sec block mining").setAction(async () => {
  await network.provider.send("evm_setIntervalMining", [2000]);
});
