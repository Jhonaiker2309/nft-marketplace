// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    
    const Market = await ethers.getContractFactory("Market");
	console.log("Deploying Market...");
	const market = await upgrades.deployProxy(Market, [], {
		initializer: "initialize",
	});
	await market.deployed();
	console.log("Market deployed to:", market.address);
}
main();