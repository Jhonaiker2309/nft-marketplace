// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GetPrices is Initializable{
    AggregatorV3Interface internal priceFeedInEthereum;
    AggregatorV3Interface internal priceFeedInLink;
    AggregatorV3Interface internal priceFeedInDai;

    /// @notice get price of ethereum
    /// @dev  get price of Ethereum in USD from chainlink
    function getLatestPriceOfEthereum() public view returns (uint256) {
        (,int price,,,) = priceFeedInEthereum.latestRoundData();
        
        // for ETH / USD price is scaled up by 10 ** 8
        return uint(price * (10 ** 10));
    }

    /// @notice get price of Link
    /// @dev  get price of Link in USD from chainlink
    function getLatestPriceOfLink() public view returns (uint256) {
        (,int price,,,) = priceFeedInLink.latestRoundData();
        
        // for LINK / USD price is scaled up by 10 ** 8
        return uint(price * (10 ** 10));
    }

    /// @notice get price of Dai
    /// @dev  get price of Dai in USD from chainlink
    function getLatestPriceOfDai() public view returns (uint256) {
        (,int price,,,) = priceFeedInDai.latestRoundData();
        
        // for DAI / USD price is scaled up by 10 ** 8  
        return uint(price * (10 ** 10));
    }    
}