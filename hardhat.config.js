require("@nomiclabs/hardhat-waffle");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
});

//Move to env before actually deploying. Don't hack me pls
module.exports = {
  solidity: "0.8.0",
};
