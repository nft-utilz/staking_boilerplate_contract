import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const MyNFT = await ethers.getContractFactory("MyNFT");
  const RewardToken = await ethers.getContractFactory("RewardToken");
  const StakeSystem = await ethers.getContractFactory("StakeSystem");
  const myNFT = await MyNFT.deploy();
  const rewardToken = await RewardToken.deploy();

  // await myNFT.deployed();
  // await rewardToken.deployed();

  const stakeSystem = await StakeSystem.deploy(
    myNFT.address,
    rewardToken.address
  );

  console.log("myNFT deployed to:", myNFT.address);
  console.log("rewardToken deployed to:", rewardToken.address);
  console.log("stakeSystem deployed to:", stakeSystem.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
