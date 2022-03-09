// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    event Buying(uint idOfItem, address tokenAddress, address seller, address buyer , uint amountOfTokenUsedToPay, uint tokenId, uint tokenAmount, string nameOfTokenOfPayment);
    event Selling(uint idOfItem, address tokenAddress, address seller, uint priceInUSD, uint tokenId, uint tokenAmount, uint deadLine);
    event CancelOffer(uint idOfItemCancelled, address tokenAddress, address seller, uint priceInUSD, uint tokenId, uint tokenAmount);

    /// @notice Constructor of upgradeable function
    /// @dev  Sets address of recipient and the Interface of The erc20 tokens Dai and Link
    function initialize() external {
        dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        link = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        recipient = payable(msg.sender);
    }

    /// @notice Create offer in Market
    /// @param tokenAddress Addres of the contract of the ERC1155 Token
    /// @param tokenId Id of the ERC1155 Token
    /// @param tokenAmount Amount of tokens that will be added to the market
    /// @param deadLine Dead to buy the item
    /// @param priceInUSD Price in USD of the tokens in the Market    
    /// @dev  Add data to mapping ItemsInTheMarket
    function createOffer(address tokenAddress,uint tokenId, uint tokenAmount, uint deadLine, uint priceInUSD) public {
        tokens1155 = IERC1155(tokenAddress);
        require(tokenAmount + tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] <= tokens1155.balanceOf(msg.sender, tokenId), "You don't have enough tokens");
        require(deadLine >= block.timestamp, "The deadline has to be after the creation of the token");
        amountOfItems++;
        ItemsInMarket[amountOfItems] = ItemInMarket(tokenAddress, payable(msg.sender), priceInUSD, tokenId, tokenAmount, deadLine);
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] += tokenAmount;
        itemIsInMarket[amountOfItems] = true;
        tokens1155.setApprovalForAll(address(this), true);
        emit Selling(amountOfItems, tokenAddress, msg.sender, priceInUSD, tokenId, tokenAmount, deadLine);
    }

    /// @notice Buy Item with ether
    /// @param idOfItem id of item in Market
    /// @dev  Send tokens from the address of the seller to the address of msg.sender and pay with ether
    function buyWithEther(uint idOfItem) public payable {
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint amountOfEtherToPay = getValueOfTokensInEther(idOfItem);   
        require(msg.value == amountOfEtherToPay, "The amount of ether is not right");
        require(ItemsInMarket[idOfItem].deadLine >= block.timestamp, "The deadline is close");
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        seller = ItemsInMarket[idOfItem].seller;
        uint etherToAdmin = (fee * amountOfEtherToPay) / 100;
        recipient.transfer(etherToAdmin);
        seller.transfer(amountOfEtherToPay - etherToAdmin);
        transferTokens(tokenAddress, seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
        emit Buying(idOfItem, tokenAddress, seller, msg.sender, amountOfEtherToPay, tokenId, tokenAmount, "Ether");
    }

    /// @notice Buy Item with Dai
    /// @param idOfItem id of item in Market
    /// @dev  Send tokens from the address of the seller to the address of msg.sender and pay with Dai
    function buyWithDai(uint idOfItem) public payable{
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 amountOfDaiToPay = ItemsInMarket[idOfItem]. priceInUSD;    
        require(dai.balanceOf(msg.sender) >= amountOfDaiToPay, "You don't have enough tokens");
        require(ItemsInMarket[idOfItem].deadLine >= block.timestamp, "The deadline is close");        
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint daiToAdmin = (fee * amountOfDaiToPay) / 100;
        dai.transferFrom(msg.sender,recipient, daiToAdmin);
        dai.transferFrom(msg.sender,seller, amountOfDaiToPay - daiToAdmin);
        transferTokens(tokenAddress,seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
        emit Buying(idOfItem, tokenAddress, seller, msg.sender, amountOfDaiToPay, tokenId, tokenAmount, "Dai");        
    }    

    /// @notice Buy Item with Link
    /// @param idOfItem id of item in Market
    /// @dev  Send tokens from the address of the seller to the address of msg.sender and pay with Link
    function buyWithLink(uint idOfItem) public payable{
        require(itemIsInMarket[idOfItem], "The item is not in the market");
        uint256 amountOfLinkToPay = getValueOfTokensInLink(idOfItem);     
        require(link.balanceOf(msg.sender) >= amountOfLinkToPay, "You don't have enough tokens");
        require(ItemsInMarket[idOfItem].deadLine >= block.timestamp, "The deadline is close");        
        seller = ItemsInMarket[idOfItem].seller;
        uint tokenAmount = ItemsInMarket[idOfItem].tokenAmount;
        address tokenAddress = ItemsInMarket[idOfItem].tokenAddress;
        uint tokenId = ItemsInMarket[idOfItem].tokenId;
        uint linkToAdmin = (fee * amountOfLinkToPay) / 100;
        link.transferFrom(msg.sender,recipient, linkToAdmin);
        link.transferFrom(msg.sender,seller, amountOfLinkToPay - linkToAdmin);
        transferTokens(tokenAddress, seller, msg.sender, tokenId, tokenAmount);
        itemIsInMarket[idOfItem] = false;
        emit Buying(idOfItem, tokenAddress, seller, msg.sender, amountOfLinkToPay, tokenId, tokenAmount, "Link");          
    }      

    /// @notice Transfer Erc1155tokens from an address to other
    /// @param tokenAddress Address of the contract of the ERC1155 Token
    /// @param from Address of the wallet where the token is
    /// @param to Address of the wallet where the token will be
    /// @param id Id of ERC1155 token
    /// @param amount Amount of tokens that will be transfered             
    /// @dev  Send tokens from the address of the seller to the address of msg.sender and pay with ether
    function transferTokens(address tokenAddress,address from, address to, uint id, uint amount) private {
        tokens1155 = IERC1155(tokenAddress);
        tokens1155.safeTransferFrom(from, to, id, amount, "");
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][from][id] -= amount;
    }

    /// @notice Cancel offer of tokens in the market
    /// @param itemId Id of item in Market
    /// @dev  Set itemIsInMarket[itemId] to false
    function cancelOffer(uint itemId) public {
        address tokenSeller = ItemsInMarket[itemId].seller;
        require(itemIsInMarket[itemId], "Item is not in market");
        require(tokenSeller == msg.sender, "You are not the owner of the tokens");        
        address tokenAddress = ItemsInMarket[itemId].tokenAddress;
        uint tokenAmount = ItemsInMarket[itemId].tokenAmount;
        uint tokenId = ItemsInMarket[itemId].tokenId;
        uint tokenPriceInUSD = ItemsInMarket[itemId].tokenId;
        tokensAlreadyInMarketByTokenAddressAndUser[tokenAddress][msg.sender][tokenId] -= tokenAmount;
        itemIsInMarket[itemId] = false;
        emit CancelOffer(itemId, tokenAddress, msg.sender, tokenPriceInUSD, tokenId, tokenAmount);
    }

    /// @notice Change recipient of the token fees
    /// @param newRecipient New address that will get the fees of the sales
    /// @dev  Change recipient to newRecipient
    function changeRecipientAddress(address newRecipient) public onlyOwner {
        recipient = payable(newRecipient);
    }

    /// @notice Change amount of fees sent to the recipient
    /// @param newFee New percentage of fees that the recipient will get
    /// @dev  Set fee to newFee
    function changePercentageOfFee(uint newFee) public onlyOwner {
        fee = newFee;
    }

    /// @notice Get price in Ether of the item in the market
    /// @param idOfItem Id of item in Market
    /// @dev  Get price of ether in USD from chainlink and do maths to get the value of the item in ether
    function getValueOfTokensInEther(uint idOfItem) public view returns (uint) {
        uint256 priceOfEthereumInUSD = getLatestPriceOfEthereum();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfEtherToPay = priceOfItemInUSD * priceOfEthereumInUSD;  
        return amountOfEtherToPay;
    }

    /// @notice Get price in Dai of the item in the market
    /// @param idOfItem Id of item in Market
    /// @dev  Get price of dai in USD from chainlink and do maths to get the value of the item in dai
    function getValueOfTokensInDai(uint idOfItem) public view returns (uint) {
        uint256 priceOfDaiInUSD = getLatestPriceOfDai();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfDaiToPay = priceOfItemInUSD * priceOfDaiInUSD;  
        return amountOfDaiToPay;
    }


    /// @notice Get price in Link of the item in the market
    /// @param idOfItem Id of item in Market
    /// @dev  Get price of link in USD from chainlink and do maths to get the value of the item in link
    function getValueOfTokensInLink(uint idOfItem) public view returns (uint) {
        uint256 priceOfLinkInUSD = getLatestPriceOfLink();
        uint256 priceOfItemInUSD = ItemsInMarket[idOfItem].priceInUSD;
        uint256 amountOfLinkToPay = priceOfItemInUSD * priceOfLinkInUSD;  
        return amountOfLinkToPay;
    }

    /// @notice Send ether from msg.sender to _to
    /// @param _to address where the ether will be sent
    /// @dev  trasfer token to _to
    function sendEther(address _to) public payable {
        payable(_to).transfer(msg.value);
    }

    /// @notice Get ether balance of user
    /// @dev  Get msg.sender.balance
    function getBalanceOfUser() public view returns(uint) {
        return msg.sender.balance;
    }
}  