// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GetPrices {
  AggregatorV3Interface internal priceFeedInEthereum;
  AggregatorV3Interface internal priceFeedInLink;
  AggregatorV3Interface internal priceFeedInDai;

  constructor() {
    priceFeedInEthereum = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    priceFeedInDai = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    //priceFeedInDai = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4);
    priceFeedInLink = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
  }

  function getLatestPriceOfEthereum() public view returns (uint256) {
    (,int price,,,) = priceFeedInEthereum.latestRoundData();
    // for ETH / USD price is scaled up by 10 ** 8
    return uint(price * (10 ** 10));
  }

  function getLatestPriceOfLink() public view returns (uint256) {
    (,int price,,,) = priceFeedInLink.latestRoundData();
    // for LINK / USD price is scaled up by 10 ** 8
    return uint(price * (10 ** 10));
  }

  function getLatestPriceOfDai() public view returns (uint256) {
    (,int price,,,) = priceFeedInDai.latestRoundData();
    // for DAI / USD price is scaled up by 10 ** 8
    
    return uint(price * (10 ** 10));
  }    
}