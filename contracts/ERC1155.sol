// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Token1155 is ERC1155 {

AggregatorV3Interface internal priceFeedInEthereum;
AggregatorV3Interface internal priceFeedInLink;
AggregatorV3Interface internal priceFeedInDai;

mapping(uint => ItemInMarket) ItemsInMarket;
mapping(uint => bool) itemIsInMarket;
mapping (address => mapping(uint => uint)) tokensAlreadyInMarket;
uint amountOfItems = 0;
struct ItemInMarket {
  address seller;
  uint priceInDollars;
  uint idOfItem;
  uint tokenAmount;
  uint deadLine;
}

    constructor() ERC1155("https://QmUuNFzKA2ya3mU8ac2vUJf3ThoqwYB5i24z7t6QNXpveT/{id}.json") {
        _mint(msg.sender, 1, 10, "");
        _mint(msg.sender, 2, 10, "");
        _mint(msg.sender, 3, 10, "");
        _mint(msg.sender, 4, 10, "");
        priceFeedInEthereum = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceFeedInDai = AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);
        priceFeedInLink = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
    }

    function uri(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {

        return string(abi.encodePacked("https://QmUuNFzKA2ya3mU8ac2vUJf3ThoqwYB5i24z7t6QNXpveT", "/", Strings.toString(tokenId), ".json"));
    }    

    function createOffer(uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) {
      require(address(this).balanceOf(msg.sender ,tokenAmount) >= tokenAmount);
      ItemsInMarket[1] = new ItemInMarket(msg.sender, priceInUSD, tokenId, tokenAmount, deadLine);
      tokensAlreadyInMarket[msg.sender][tokenId] += tokenAmount;
    }

    function SellWithEther(uint idOfItem) {
      uint priceOfEtherInUSD = priceFeedInEthereum.getLatestPrice();
      uint priceOfItemInUSD = ItemsInMarket[idOfItem].priceInDollars;
      uint amountOfEther = priceOfItemInUSD / priceOfEtherInUSD;
      
      require(msg.sender.balance >= amountOfEther);
    }

    function SellWithDai(uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) {
      uint priceOfDaiInUSD = priceFeedInDai.getLatestPrice();
      uint priceOfItemInUSD = ItemsInMarket[idOfItem].priceInDollars;
      uint amountOfDai = priceOfItemInUSD / priceOfDaiInUSD;
      
      //Dai.balance >= msg.sender.avadasd require(msg.sender.balance >= amountOfEther);
 
    }

    function SellWithLink(uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) {
      uint priceOfDaiInUSD = priceFeedInDai.getLatestPrice();
      uint priceOfItemInUSD = ItemsInMarket[idOfItem].priceInDollars;
      uint amountOfDai = priceOfItemInUSD / priceOfDaiInUSD;
      
      //Dai.balance >= msg.sender.avadasd require(msg.sender.balance >= amountOfEther);
  } 