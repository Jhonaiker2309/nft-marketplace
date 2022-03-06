const { expect } = require("chai");
const { ethers } = require( "hardhat" );

describe("Token20 contract", function () {
  let owner, etherscanAddress1, etherscanAddress2, etherscanAddress3, Market, market, Token1155, token1155
  let account1, account2, account3
  

  etherscanAddress1 = "0x8fEEaa5f3Bcc9700fb8D44FC1ba018A958f67bFe";
  etherscanAddress2 = "0xDD6242408D16a60C1cb5bf96c816daA0a8490773";
  etherscanAddress3 = "0x0eeb4dd1b3fe9bd8e7cdf9781a3213b5956fd906";
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    Market = await ethers.getContractFactory("Market");
    Token1155 = await ethers.getContractFactory("Token1155");
    [owner] = await ethers.getSigners();
    
     await hre.network.provider.request({
			method: "hardhat_impersonateAccount",
			params: [etherscanAddress1]
		});

    [account1, account2, account3] = await ethers.getSigner(etherscanAddress1);
    token1155 = await Token1155.deploy()
    market = await Market.deploy(token1155.address);
  });

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
        expect(account1.address).to.be.equal(etherscanAddress1)
        //expect(await market.connect(account1).getBalanceOfUser()).to.be.equal(20);
        let balance = await market.getBalanceOfToken(owner.address, 1)
        expect(await balance).to.be.equal(10);
    });
  });
});
