const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("TestContract");
  const contract = await Contract.deploy("BBBBBB");

  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
  await contract.guessWord("ABCDEF");
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
})