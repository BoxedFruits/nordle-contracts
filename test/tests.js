const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Nordle", () => {
  var contract;
  const secretWord = "ABBBBB";

  beforeEach(async () => {
    const Contract = await ethers.getContractFactory("TestContract");
    contract = await Contract.deploy(secretWord);
    await contract.deployed();
  });

  it("should set the currentGameTimeStamp when setting a new secret word", async() => {
      const oldTimeStamp = await contract.currentGameTimeStamp();
      await contract.setSecretWord("AAAAAA");
      expect(await contract.currentGameTimeStamp()).to.not.equal(oldTimeStamp);
  });

  it("should not allow the user to play the game more than 'maxTries' times", async () => {
    const maxTries = await contract.maxTries();
    console.log(maxTries);

    for (let i = 0; i < maxTries; i++) {
      await contract.guessWord("AAAAAA");
    }

    expect(contract.guessWord("AAAAAA")).to.revertedWith(Error, 'Maxed out guesses for this Nordle');
  });

  it("should not allow the user to play the game if they solved the Nordle", async () => {
    await contract.guessWord("secretWord");

    expect(contract.guessWord("AAAAAA")).to.revertedWith(Error, 'Maxed out guesses for this Nordle or already solved it!');
  });

  it("should reset the address's tries if a new game starts", async () => {
    const tries = 3;

    for (let i = 0; i < tries; i++) {
      await contract.guessWord("AAAAAA");
    }

    const [owner] = await ethers.getSigners();

    expect(await contract.userTries(owner.address)).to.equal(3);

    await contract.setSecretWord("UUUUUU");
    await contract.guessWord("AAAAAA");
    expect(await contract.userTries(owner.address)).to.equal(1); //Should be one because userTries resets once the user tries again. Then the counter is incremented
  });

  describe("Validation rowEmojis", () => {

    it("show a row of ⬛ if all the letters are wrong", async () => {
      await contract.guessWord("PPPPPP");

      const [owner] = await ethers.getSigners();
      const currentTokenId = await contract.currentToken(owner.address);

      expect(await contract.tokenRowEmojis(currentTokenId, 0)).to.equal("⬛⬛⬛⬛⬛⬛");
    });

    it("show a some 🟨 of all the letters are somewhere in the word", async() => {
      await contract.guessWord("PPPPPA");

      const [owner] = await ethers.getSigners();
      const currentTokenId = await contract.currentToken(owner.address);

      expect(await contract.tokenRowEmojis(currentTokenId, 0)).to.equal("⬛⬛⬛⬛⬛🟨");
    });
    
    // Might need more test cases
    it("show a single 🟨 if the letters are somewhere in the word but is repeated in the guess", async() => {
      await contract.guessWord("PPPPAA");

      const [owner] = await ethers.getSigners();
      const currentTokenId = await contract.currentToken(owner.address);

      expect(await contract.tokenRowEmojis(currentTokenId, 0)).to.equal("⬛⬛⬛⬛🟨⬛");
    });

    it("show a row of 🟩 if all the letters are correct", async() => {
      await contract.guessWord(secretWord);

      const [owner] = await ethers.getSigners();
      const currentTokenId = await contract.currentToken(owner.address);

      expect(await contract.tokenRowEmojis(currentTokenId, 0)).to.equal("🟩🟩🟩🟩🟩🟩");
    });
  });
});