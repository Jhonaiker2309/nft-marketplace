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
address payable public recipient;
uint public amountOfItems = 0;
uint public fee = 1;

mapping(uint => ItemInMarket) ItemsInMarket;
mapping(uint => bool) public itemIsInMarket;
mapping(address => mapping(address => mapping(uint => uint))) public tokensAlreadyInMarketByTokenAddressAndUser;

struct ItemInMarket {
    address tokenAddress;
    address payable seller;
    uint priceInUSD;
    uint tokenId;
    uint tokenAmount;
    uint deadLine;
}

    constructor()  {
        dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        link = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        recipient = payable(msg.sender);
    }

    function createOffer(address tokenAddress,uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) public {
        tokens1155 = IERC1155(tokenAddress);
        require(tokenAmount + tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] <= tokens1155.balanceOf(msg.sender, tokenId), "You don't have enough tokens");
        require(deadLine >= block.timestamp, "The deadline has to be after the creation of the token");
        amountOfItems++;
        ItemsInMarket[amountOfItems] = ItemInMarket(tokenAddress, payable(msg.sender), priceInUSD, tokenId, tokenAmount, deadLine);
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] += tokenAmount;
        itemIsInMarket[amountOfItems] = true;
        tokens1155.setApprovalForAll(address(this), true);
    }

    function SellWithEther(uint idOfItem) public payable {
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint amountOfEtherToPay = getValueOfTokensInEther(idOfItem);   
        require(msg.value == amountOfEtherToPay, "The amount of ether is not right");
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
        uint256 amountOfDaiToPay = ItemsInMarket[idOfItem]. priceInUSD;    
        require(dai.balanceOf(msg.sender) >= amountOfDaiToPay, "You don't have enough tokens");
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint daiToAdmin = (fee * amountOfDaiToPay) / 100;
        dai.transferFrom(msg.sender,recipient, daiToAdmin);
        dai.transferFrom(msg.sender,seller, amountOfDaiToPay - daiToAdmin);
        transferTokens(tokenAddress,seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
    }    

    function SellWithLink(uint idOfItem) public payable{
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 amountOfLinkToPay = getValueOfTokensInLink(idOfItem);     
        require(link.balanceOf(msg.sender) >= amountOfLinkToPay, "You don't have enough tokens");
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        uint linkToAdmin = (fee * amountOfLinkToPay) / 100;
        link.transferFrom(msg.sender,recipient, linkToAdmin);
        link.transferFrom(msg.sender,seller, amountOfLinkToPay - linkToAdmin);
        transferTokens(tokenAddress, seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
    }      

    function transferTokens(address tokenAddress,address from, address to, uint id, uint amount) private {
        tokens1155 = IERC1155(tokenAddress);
        tokens1155.safeTransferFrom(from, to, id, amount, "");
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][from][id] -= amount;
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

    function changeRecipientAddress(address newRecipient) public onlyOwner {
        recipient = payable(newRecipient);
    }

    function changePercentageOfFee(uint newFee) public onlyOwner {
        fee = newFee;
    }

    function getValueOfTokensInEther(uint idOfItem) public view returns (uint) {
        uint256 priceOfEthereumInUSD = getLatestPriceOfEthereum();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfEtherToPay = priceOfItemInUSD * priceOfEthereumInUSD;  
        //return amountOfEtherToPay;
        return amountOfEtherToPay;
    }

    function getValueOfTokensInDai(uint idOfItem) public view returns (uint) {
        uint256 priceOfDaiInUSD = getLatestPriceOfDai();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfDaiToPay = priceOfItemInUSD * priceOfDaiInUSD;  
        return amountOfDaiToPay;
    }

    function getValueOfTokensInLink(uint idOfItem) public view returns (uint) {
        uint256 priceOfLinkInUSD = getLatestPriceOfLink();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfLinkToPay = priceOfItemInUSD * priceOfLinkInUSD;  
        return amountOfLinkToPay;
    }

    function sendEther(address _to) public payable {
      payable(_to).transfer(msg.value);
    }

    function getBalanceOfUser() public view returns(uint) {
        return msg.sender.balance;
    }
}  