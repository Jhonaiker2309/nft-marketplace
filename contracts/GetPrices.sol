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
    priceFeedInLink = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
  }

  function getLatestPriceOfEthereum() public view returns (uint256) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeedInEthereum.latestRoundData();
    // for ETH / USD price is scaled up by 10 ** 8
    require(timeStamp > 0, "Round not complete");
    return uint(price / 1e8);
  }

  function getLatestPriceOfLink() public view returns (uint256) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeedInLink.latestRoundData();
    // for ETH / USD price is scaled up by 10 ** 8
    require(timeStamp > 0, "Round not complete");
    return uint(price / 1e8);
  }

  function getLatestPriceOfDai() public view returns (uint256) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeedInDai.latestRoundData();
    // for ETH / USD price is scaled up by 10 ** 8
    require(timeStamp > 0, "Round not complete");
    return uint(price / 1e8);
  }    
}