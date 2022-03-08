const { expect } = require("chai");
const { ethers } = require( "hardhat" );
const { daiABI, parallelABI, linkABI } = require("../abis/dai.json");
const {increaseBlocks, increaseTime, currentTime, toDays, toWei, fromWei} = require("./utils")
describe("Token20 contract", function () {
  let owner,
		etherscanAddress1,
		etherscanAddress2,
		etherscanAddress3,
        etherscanAddressTokenOwner,
        ethercansWhaleAddress,
		Market,
		market,
        dai,
        whale,
        link,
        pallalel

  let account1, account2, account3, diome;
  
  ethercansWhaleAddress = "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE";
  etherscanAddress1 = "0x8fEEaa5f3Bcc9700fb8D44FC1ba018A958f67bFe";
  etherscanAddress2 = "0xDD6242408D16a60C1cb5bf96c816daA0a8490773";
  etherscanAddress3 = "0x0eeb4dd1b3fe9bd8e7cdf9781a3213b5956fd906";
  etherscanAddressTokenOwner = "0xa36df1827cebc277fb49e44cb2b71e100ec5e108";

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    Market = await ethers.getContractFactory("Market");
    //Token1155 = await ethers.getContractFactory("Token1155");
    [owner] = await ethers.getSigners();
    
    await hre.network.provider.request({
			method: "hardhat_impersonateAccount",
			params: [etherscanAddress1]
		});

    account1 = await ethers.getSigner(etherscanAddress1);

    await hre.network.provider.request({
		method: "hardhat_impersonateAccount",
		params: [etherscanAddress2],
	});

	account2 = await ethers.getSigner(etherscanAddress2);

    await hre.network.provider.request({
		method: "hardhat_impersonateAccount",
		params: [etherscanAddress3],
	});

	account3 = await ethers.getSigner(etherscanAddress3);

    await hre.network.provider.request({
			method: "hardhat_impersonateAccount",
			params: [etherscanAddressTokenOwner],
		});

	diome = await ethers.getSigner(etherscanAddressTokenOwner);

    await hre.network.provider.request({
			method: "hardhat_impersonateAccount",
			params: [ethercansWhaleAddress],
		});

	whale = await ethers.getSigner(ethercansWhaleAddress);    

    



    dai = new ethers.Contract("0x6b175474e89094c44da98b954eedeac495271d0f",daiABI);
    link = new ethers.Contract("0x514910771AF9Ca656af840dff83E8264EcF986CA",linkABI);
    parallel = new ethers.Contract("0x76be3b62873462d2142405439777e971754e8e77",parallelABI);
    //token1155 = await Token1155.deploy()
    market = await Market.deploy();

  });

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
        expect(account1.address).to.be.equal(etherscanAddress1)
        //expect(await market.connect(account1).getBalanceOfUser()).to.be.equal(20);
        await market.connect(owner).sendEth(diome.address, {value: toWei(100)})
        //console.log(await market.connect(whale).sendEth(diome.address))
       
        await market.connect(diome).createOffer(parallel.address, 10254, 1, 10000000000000, 10);
        //await market.connect(diome).createOffer(parallel.address, 10254, 1, 10000000000000, 10);

        await parallel.connect(diome).setApprovalForAll(market.address, true)
       
        console.log(await parallel.connect(diome).isApprovedForAll(diome.address, market.address))
        let balance = await parallel.connect(owner).balanceOf(diome.address, 10254);
        console.log(await balance)
        await market.connect(owner).SellWithEther(1, {value: toWei(0.01)})

        balance = await parallel.connect(owner).balanceOf(diome.address, 10254);
        expect(balance).to.be.equal(0)  
        balance = await parallel.connect(owner).balanceOf(owner.address, 10254);
        expect(balance).to.be.equal(1)
    });
  });
});
