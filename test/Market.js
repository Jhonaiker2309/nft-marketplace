const { expect } = require("chai");
const { ethers } = require( "hardhat" );
const { daiABI, parallelABI, linkABI } = require("../abis/abis.json");
const {toWei} = require("./utils")
describe("Market contract", function () {

    let etherscanAddressTokenOwner
    let Market, market
    let link, parallel, dai
    let owner, account1, account2, accountWithDai, accountWithLink, accountWithToken;

    etherscanAddressWithDai = "0x8fEEaa5f3Bcc9700fb8D44FC1ba018A958f67bFe";
    etherscanAddressWithLink = "0xc287b9255fe158226cbf04b7d2c3915bd5c1bc99";
    etherscanAddressTokenOwner = "0xa36df1827cebc277fb49e44cb2b71e100ec5e108";

    beforeEach(async function () {
        Market = await ethers.getContractFactory("Market");
        [owner, account1, account2] = await ethers.getSigners();
    
        await hre.network.provider.request({
			method: "hardhat_impersonateAccount",
			params: [etherscanAddressWithDai]
		});

        accountWithDai = await ethers.getSigner(etherscanAddressWithDai);

        await hre.network.provider.request({
		    method: "hardhat_impersonateAccount",
		    params: [etherscanAddressWithLink],
	    });

	    accountWithLink = await ethers.getSigner(etherscanAddressWithLink);

        await hre.network.provider.request({
		    method: "hardhat_impersonateAccount",
		    params: [etherscanAddressTokenOwner],
	    });

	    accountWithToken = await ethers.getSigner(etherscanAddressTokenOwner);

        dai = new ethers.Contract("0x6b175474e89094c44da98b954eedeac495271d0f",daiABI);
        link = new ethers.Contract("0x514910771AF9Ca656af840dff83E8264EcF986CA",linkABI);
        parallel = new ethers.Contract("0x76be3b62873462d2142405439777e971754e8e77",parallelABI);
        market = await Market.deploy();
        await market.initialize()
});

    describe("Deployment", function () {

        it("Check if addresses are right", async function () {
            expect(accountWithDai.address.toLowerCase()).to.be.equal(etherscanAddressWithDai.toLowerCase())
            expect(accountWithLink.address.toLowerCase()).to.be.equal(etherscanAddressWithLink.toLowerCase())
            expect(accountWithToken.address.toLowerCase()).to.be.equal(etherscanAddressTokenOwner.toLowerCase())
        })

        it("Test creation of item in market", async function () {
            await market.connect(account1).sendEther(accountWithToken.address ,{value: toWei(10)})

            expect(await market.amountOfItems()).to.be.equal(0);
            expect(await market.itemIsInMarket(1)).to.be.equal(false);

            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithToken.address, 10254)).to.be.equal(0);

            await expect(market.connect(accountWithToken).createOffer(parallel.address, 10254, 10, 100000000000000, 30)).to.be.revertedWith("You don't have enough tokens")
            await expect(market.connect(accountWithToken).createOffer(parallel.address, 10254, 1, 100, 30)).to.be.revertedWith("The deadline has to be after the creation of the token")

            await market.connect(accountWithToken).createOffer(parallel.address, 10254, 1, 1000000000000000, 30)  

            expect(await market.amountOfItems()).to.be.equal(1);
            expect(await market.itemIsInMarket(1)).to.be.equal(true);
            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithToken.address, 10254)).to.be.equal(1);     
        }) 

        it("Test payment with ethereum", async function () {
            await market.connect(accountWithToken).createOffer(parallel.address, 10254, 1, 1000000000000000, 1)

            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithToken.address, 10254)).to.be.equal(1)

            await parallel.connect(accountWithToken).setApprovalForAll(market.address, true)

            expect(await parallel.connect(accountWithToken).balanceOf(accountWithToken.address,10254)).to.be.equal(1)
            expect(await parallel.connect(accountWithToken).balanceOf(account2.address,10254)).to.be.equal(0)

            await expect(market.connect(account2).buyWithEther(2, {value: toWei(5)})).to.be.revertedWith("The item is not in the market")
            await expect(market.connect(account2).buyWithEther(1, {value: toWei(5)})).to.be.revertedWith("The amount of ether is not right")

            let amountOfEtherToPay = await market.connect(owner).getValueOfTokensInEther(1)

            await market.connect(account2).buyWithEther(1, {value: amountOfEtherToPay})

            expect(await parallel.connect(accountWithToken).balanceOf(accountWithToken.address,10254)).to.be.equal(0)
            expect(await parallel.connect(accountWithToken).balanceOf(account2.address,10254)).to.be.equal(1)
            expect(await market.itemIsInMarket(1)).to.be.equal(false)
            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithToken.address, 10254)).to.be.equal(0)
        })

        it("Test payment with Dai", async function () {
            expect(await parallel.connect(accountWithToken).balanceOf(account2.address,10254)).to.be.equal(1)

            await market.connect(account2).createOffer(parallel.address, 10254, 1, 1000000000000000, 3)

            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, account2.address, 10254)).to.be.equal(1)

            await parallel.connect(account2).setApprovalForAll(market.address, true)

            expect(await parallel.connect(accountWithToken).balanceOf(account2.address,10254)).to.be.equal(1)
            expect(await parallel.connect(accountWithToken).balanceOf(accountWithDai.address,10254)).to.be.equal(0)

            await expect(market.connect(account1).buyWithDai(2)).to.be.revertedWith("The item is not in the market")
            await expect(market.connect(account1).buyWithDai(1)).to.be.revertedWith("You don't have enough tokens")

            let priceInDai = await market.getValueOfTokensInDai(1)

            await dai.connect(accountWithDai).approve(market.address, priceInDai)
            await market.connect(accountWithDai).buyWithDai(1)

            expect(await parallel.connect(account2).balanceOf(account2.address,10254)).to.be.equal(0)
            expect(await parallel.connect(accountWithToken).balanceOf(accountWithDai.address,10254)).to.be.equal(1)
            expect(await market.itemIsInMarket(1)).to.be.equal(false)
            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithToken.address, 10254)).to.be.equal(0)
        })

        it("Test payment with Link", async function () {
            expect(await parallel.connect(accountWithDai).balanceOf(accountWithDai.address,10254)).to.be.equal(1)

            await market.connect(accountWithDai).createOffer(parallel.address, 10254, 1, 1000000000000000, 3)

            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithDai.address, 10254)).to.be.equal(1)

            await parallel.connect(accountWithDai).setApprovalForAll(market.address, true)

            expect(await parallel.connect(accountWithDai).balanceOf(accountWithDai.address,10254)).to.be.equal(1)
            expect(await parallel.connect(accountWithDai).balanceOf(accountWithLink.address,10254)).to.be.equal(0)

            await expect(market.connect(account1).buyWithLink(2)).to.be.revertedWith("The item is not in the market")
            await expect(market.connect(account1).buyWithLink(1)).to.be.revertedWith("You don't have enough tokens")

            let priceInLink = await market.getValueOfTokensInLink(1)

            await link.connect(accountWithLink).approve(market.address, priceInLink)

            await market.connect(accountWithLink).buyWithLink(1)

            expect(await parallel.connect(accountWithDai).balanceOf(accountWithDai.address,10254)).to.be.equal(0)
            expect(await parallel.connect(accountWithLink).balanceOf(accountWithLink.address,10254)).to.be.equal(1)
            expect(await market.itemIsInMarket(1)).to.be.equal(false)
            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithDai.address, 10254)).to.be.equal(0)
        })

        it("Test cancell offer", async function () {
            await expect(market.connect(account1).cancelOffer(2)).to.be.revertedWith("Item is not in market")

            expect(await parallel.connect(accountWithLink).balanceOf(accountWithLink.address,10254)).to.be.equal(1)

            await market.connect(accountWithLink).createOffer(parallel.address, 10254, 1, 1000000000000000, 3)

            expect(await market.itemIsInMarket(1)).to.be.equal(true)
            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithLink.address, 10254)).to.be.equal(1)

            await expect(market.connect(account1).cancelOffer(1)).to.be.revertedWith("You are not the owner of the tokens")

            await market.connect(accountWithLink).cancelOffer(1)

            expect(await market.tokensAlreadyInMarketByTokenAddressAndUser(parallel.address, accountWithLink.address, 10254)).to.be.equal(0)
            expect(await market.itemIsInMarket(1)).to.be.equal(false)
        })

        it("Test fuctions that change transaction values", async function() {
					expect(await market.recipient()).to.be.equal(owner.address);
					expect(await market.fee()).to.be.equal(1);

					await market.changeRecipientAddress(account1.address)
					 await market.changePercentageOfFee(5)

					expect(await market.recipient()).to.be.equal(account1.address)
					expect(await market.fee()).to.be.equal(5);
				})        
    });
});


