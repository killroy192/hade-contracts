const config = require("dotenv").config();
const { task } = require("hardhat/config");
const { getLock, getDeployment } = require("@dgma/hardhat-sol-bundler");

const MINT = "mint";

task(MINT, "Mint mock tokens to faucet").setAction(async (_, hre) => {
  const { ExposureToken, HedgeToken } = getLock(getDeployment(hre)?.lockFile)[hre.network.name];
  const ExposureTokenContract = await hre.ethers.getContractAt(
    ExposureToken.abi,
    ExposureToken.address,
  );
  const HedgeTokenContract = await hre.ethers.getContractAt(HedgeToken.abi, HedgeToken.address);
  const defaultAddr = (await hre.ethers.getSigners())[0].address;
  const faucetAddr =
    hre.network.name === "localhost" ? defaultAddr : config?.parsed?.FAUCET_ADDRESS || defaultAddr;
  await ExposureTokenContract.mintTo(faucetAddr, hre.ethers.parseEther("10000"));
  await HedgeTokenContract.mintTo(faucetAddr, hre.ethers.parseEther("1000000000000000"));
});
