// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./GetPrices.sol";

contract Market is GetPrices {


IERC1155 public tokens1155;
IERC20 public dai;
IERC20 public link;
address payable seller;
uint fee = 1;
address payable recipient;
mapping(uint => ItemInMarket) ItemsInMarket;
mapping(uint => bool) itemIsInMarket;
mapping (address => mapping(uint => uint)) tokensAlreadyInMarket;
uint amountOfItems = 0;
struct ItemInMarket {
  address payable seller;
  uint priceInUSD;
  uint tokenId;
  uint tokenAmount;
  uint deadLine;
}

    constructor(address tokensAddress) {
        dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        link = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        tokens1155 = IERC1155(tokensAddress);
    }
    
    function getBalanceOfToken(address account, uint id) public view returns(uint){
        return tokens1155.balanceOf(account, id);
    }
    function createOffer(uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) public {
      require(tokenAmount + tokensAlreadyInMarket[msg.sender][tokenId] <= tokens1155.balanceOf(msg.sender, tokenId), "Tou don't have enough tokens");
      amountOfItems++;
      ItemsInMarket[amountOfItems] = ItemInMarket(payable(msg.sender), priceInUSD, tokenId, tokenAmount, deadLine);
      tokensAlreadyInMarket[msg.sender][tokenId] += tokenAmount;
      tokens1155.setApprovalForAll(address(this), true);
    }

    function changeRecipientAddress(address newRecipient) public {
        recipient = payable(newRecipient);
    }

    function changePercentageOfFee(uint newFee) public {
      fee = newFee;
    }

    function SellWithEther(uint idOfItem) public payable{
      require(itemIsInMarket[idOfItem], "The item is not in the market");
      uint256 priceOfEthereumInUSD = getLatestPriceOfEthereum();
      uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
      uint256 amountOfEtherToPay = priceOfItemInUSD / priceOfEthereumInUSD;      
      require(msg.value == amountOfEtherToPay);
      uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
      uint tokenId = ItemsInMarket[idOfItem].tokenId;
      seller = ItemsInMarket[idOfItem].seller;
      uint etherToAdmin = (fee * amountOfEtherToPay) / 100;
      recipient.transfer(etherToAdmin);
      seller.transfer(amountOfEtherToPay - etherToAdmin);
      transferTokens(seller, msg.sender, tokenId, tokenAmount);
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
      uint daiToAdmin = (fee * amountOfDaiToPay) / 100;
      dai.transfer(recipient, daiToAdmin);
      dai.transfer(seller, amountOfDaiToPay - daiToAdmin);
      transferTokens(seller, msg.sender, tokenId, tokenAmount);
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
      uint tokenId = ItemsInMarket[idOfItem].tokenId;
      uint linkToAdmin = (fee * amountOfLinkToPay) / 100;
      link.transfer(recipient, linkToAdmin);
      link.transfer(seller, amountOfLinkToPay - linkToAdmin);
      transferTokens(seller, msg.sender, tokenId, tokenAmount);
      itemIsInMarket[idOfItem] = false;
    }      

    function transferTokens(address from, address to, uint id, uint amount) private {
        tokens1155.safeTransferFrom(from, to, id, amount, "");
    }

    function cancelOffer(uint itemId) public {
      itemIsInMarket[itemId] = false;
    }

    function getBalanceOfUser() public view returns(uint) {
      return msg.sender.balance;
    }
}  