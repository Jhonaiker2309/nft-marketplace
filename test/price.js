const { expect } = require("chai");

describe("Token20 contract", function () {
  let totalSupply = 10 ** 6;
  let Token20;
  let token;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    getPrice = await ethers.getContractFactory("TestChainlink");
    [owner, addr1, addr2] = await ethers.getSigners();

    getTokenPrice = await getPrice.deploy();
  });

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
      console.log(await getTokenPrice.getLatestPrice())
    });
  });
});
