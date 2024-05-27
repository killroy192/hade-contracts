const { getLock } = require("@dgma/hardhat-sol-bundler");

async function register(hre) {
  const { Registry, Balancer } = getLock(
    hre.userConfig.networks[hre.network.name].deployment.lockFile,
  )[hre.network.name];

  const registry = await hre.ethers.getContractAt("Registry", Registry.address);

  await registry.register(Balancer.address);
}

task("register", "Register balancer").setAction(async (_, hre) =>
  register(hre).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  }),
);
