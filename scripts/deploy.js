// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function deployContract(name, ...constructorArgs) {
  if (constructorArgs.length === 0) {
    constructorArgs = null;
  }

  const Contract = await hre.ethers.getContractFactory(name);
  const contract = await Contract.deploy.apply(Contract, constructorArgs);

  return await contract
    .deployed()
    .then(() => {
      console.log(`${name} deployed to:`, contract.address);
      deployedContracts[name] = contract.address;
      return contract;
    }).catch((err) => {
      console.log(arguments);
    });
};

async function main() {
    const fundMe = await deployContract("FundMe");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
