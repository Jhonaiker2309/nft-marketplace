// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GetPrices.sol";

contract Market is GetPrices, Ownable {


IERC1155 public tokens1155;
IERC20 public dai;
IERC20 public link;

address payable seller;
address payable recipient;
uint amountOfItems = 0;
uint fee = 1;

mapping(uint => ItemInMarket) ItemsInMarket;
mapping(uint => bool) itemIsInMarket;
mapping(address => mapping(address => mapping(uint => uint))) tokensAlreadyInMarketByTokenAddressAndUser;

struct ItemInMarket {
    address tokenAddress;
    address payable seller;
    uint priceInUSD;
    uint tokenId;
    uint tokenAmount;
    uint deadLine;
}

    constructor() {
        dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        link = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    }
    
    function getBalanceOfToken(address tokenAddress, address account, uint id) public returns(uint){
        tokens1155 = IERC1155(tokenAddress);
        return tokens1155.balanceOf(account, id);
    }

    function createOffer(address tokenAddress,uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) public {
        tokens1155 = IERC1155(tokenAddress);
        require(tokenAmount + tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] <= tokens1155.balanceOf(msg.sender, tokenId), "You don't have enough tokens");
        require(deadLine >= block.timestamp, "The offers passed away its deadline");
        amountOfItems++;
        ItemsInMarket[amountOfItems] = ItemInMarket(tokenAddress, payable(msg.sender), priceInUSD, tokenId, tokenAmount, deadLine);
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] += tokenAmount;
        tokens1155.setApprovalForAll(address(this), true);
    }

    function SellWithEther(uint idOfItem) public payable {
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 priceOfEthereumInUSD = getLatestPriceOfEthereum();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfEtherToPay = priceOfItemInUSD / priceOfEthereumInUSD;      
        require(msg.value == amountOfEtherToPay);
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        seller = ItemsInMarket[idOfItem].seller;
        uint etherToAdmin = (fee * amountOfEtherToPay) / 100;
        recipient.transfer(etherToAdmin);
        seller.transfer(amountOfEtherToPay - etherToAdmin);
        transferTokens(tokenAddress, seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
    }

    function SellWithDai(uint idOfItem) public payable{
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 priceOfDaiInUSD = getLatestPriceOfDai();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfDaiToPay = priceOfItemInUSD / priceOfDaiInUSD;      
        require(dai.balanceOf(msg.sender) >= amountOfDaiToPay);
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint daiToAdmin = (fee * amountOfDaiToPay) / 100;
        dai.transfer(recipient, daiToAdmin);
        dai.transfer(seller, amountOfDaiToPay - daiToAdmin);
        transferTokens(tokenAddress,seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
    }    

    function SellWithLink(uint idOfItem) public payable{
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 priceOfLinkInUSD = getLatestPriceOfLink();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfLinkToPay = priceOfItemInUSD / priceOfLinkInUSD;      
        require(dai.balanceOf(msg.sender) >= amountOfLinkToPay);
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        uint linkToAdmin = (fee * amountOfLinkToPay) / 100;
        link.transfer(recipient, linkToAdmin);
        link.transfer(seller, amountOfLinkToPay - linkToAdmin);
        transferTokens(tokenAddress, seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
    }      

    function transferTokens(address tokenAddress,address from, address to, uint id, uint amount) private {
        tokens1155 = IERC1155(tokenAddress);
        tokens1155.safeTransferFrom(from, to, id, amount, "");
    }

    function cancelOffer(uint itemId) public {
        address tokenSeller = ItemsInMarket[itemId].seller;
        require(itemIsInMarket[itemId], "Item is not in market");
        require(tokenSeller == msg.sender, "You are not the owner of the tokens");        
        address tokenAddress = ItemsInMarket[itemId].tokenAddress;
        uint tokenAmount = ItemsInMarket[itemId].tokenAmount;
        uint tokenId = ItemsInMarket[itemId].tokenId;
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] -= tokenAmount;
        itemIsInMarket[itemId] = false;
    }

    function getBalanceOfUser() public view returns(uint) {
        return msg.sender.balance;
    }


    function changeRecipientAddress(address newRecipient) public onlyOwner {
        recipient = payable(newRecipient);
    }

    function changePercentageOfFee(uint newFee) public onlyOwner {
        fee = newFee;
    }
}  