//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IToken.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";




contract Market is ReentrancyGuard{
    uint256 roundTime;
    uint256 curentRoundEndTime;
    uint256 private theHeadOfOrders;

    using SafeERC20 for Itoken;
    using Counters for Counters.Counter;
    Counters.Counter private _ordersIds;
    Itoken private _boundedTkn;


    enum Phase{
        Sale,
        Trade
    }

    struct RoundInfo{
        uint256 ethSpentDurTrade;
        uint256 tknBoughtDurSale;
        uint256 amountToBurn;
        uint256 amountToMint;
        uint256 endTime;
        uint256 tradesDone;
        uint256 currentPriceForSale;
        bool init;
        Phase nextPhase;

    }

    struct Orders{
        uint256 amount;
        uint256 price;
        uint256 pointTo;
        uint256 pointFrom;
        address owner;
        
    }
    struct refers{
        address payable lvl1; //5% on sale | 2.5% on trade
        address payable lvl2; //3% on sale | 2.5% on trade
    }

    event salePhaseStarted(uint256 price, uint256 amountToMint);
    event tradePhaseStarted();
    event orderAdded(uint256 orderId, uint256 price, address owner);
    event redeemed(uint256 orderId, uint256 amount, uint256 price, address seller, address buyer);
    event orderRemoved(uint256 orderId);
    event tknBoughtOnSale(uint256 amount, address buyer);
    event soldOut(uint256 endTime);
    
    //mapping(address => mapping(address => address)) refs;
    mapping(uint256 => Orders) public IdToOrder;
    mapping(address => refers) public addrToRefers;

    RoundInfo public roundInfo;
    //v/new price for new saleround = amount of tokens to mint on contract
    //burn all after sale round 

    constructor(address _tokenACDM, uint256 _roundTime) {
        _boundedTkn = Itoken(_tokenACDM);
        theHeadOfOrders = 0;
        roundTime = _roundTime;
        roundInfo = RoundInfo(
            0,
            0,
            0,
            100000,
            block.timestamp,
            1,
            1e13,
            true,
            Phase.Sale
        );
    }

    function registration(address payable _refer) public{
        require(addrToRefers[msg.sender].lvl1 == address(0), "already registered");
        if(_refer != address(0)){
            addrToRefers[msg.sender].lvl1 = _refer;
            if (addrToRefers[_refer].lvl1 != address(0)){
                addrToRefers[msg.sender].lvl2 = addrToRefers[_refer].lvl1;
            }
        }

    }

    function addOrder(uint256 amountACDM, uint256 price) public {
        require(roundInfo.nextPhase == Phase.Sale, "Current phase is not Trade");

        _boundedTkn.safeTransferFrom(msg.sender, address(this), amountACDM);
        _ordersIds.increment();
        console.log(_ordersIds.current());

        IdToOrder[_ordersIds.current()].amount = amountACDM;
        IdToOrder[_ordersIds.current()].price = price;
        IdToOrder[_ordersIds.current()].owner = msg.sender;
        console.log(IdToOrder[_ordersIds.current()].amount);

        
        IdToOrder[theHeadOfOrders].pointTo = _ordersIds.current();
        IdToOrder[_ordersIds.current()].pointFrom = theHeadOfOrders;
        theHeadOfOrders = _ordersIds.current();

        emit orderAdded(_ordersIds.current(), price, msg.sender);
    }

    function removeOrder(uint256 orderId) public {
        

        require(roundInfo.nextPhase == Phase.Sale, "Current phase is not Trade");
        require(orderId != 0, "Id is not valid");
        require(orderId <= theHeadOfOrders, "Id is not valid");
        require(msg.sender == IdToOrder[orderId].owner || msg.sender == address(this), "Not an owner");
        require(IdToOrder[orderId].amount != 0, "Already removed order");


        _boundedTkn.safeTransfer(msg.sender, IdToOrder[_ordersIds.current()].amount);
        IdToOrder[_ordersIds.current()].amount = 0;
        IdToOrder[_ordersIds.current()].price = 0;
        IdToOrder[_ordersIds.current()].owner = address(0);
        if(orderId == theHeadOfOrders){
            IdToOrder[IdToOrder[orderId].pointFrom].pointTo = 0;
            theHeadOfOrders = IdToOrder[orderId].pointFrom;
            IdToOrder[orderId].pointFrom = 0;
        }else{
            IdToOrder[IdToOrder[orderId].pointTo].pointFrom = IdToOrder[orderId].pointFrom;
            IdToOrder[IdToOrder[orderId].pointFrom].pointTo = IdToOrder[orderId].pointTo;
        }
        
        emit orderRemoved(orderId);

        
    }

    function redeemOrder(uint256 orderId) external payable nonReentrant{
        require(roundInfo.nextPhase == Phase.Sale, "Current phase is not Trade");
        require(IdToOrder[orderId].amount > 0, "There is no order by given Id");
        require(IdToOrder[orderId].amount >= msg.value / IdToOrder[orderId].price, "Not enough supply to buy");

        bool sent;
        bytes memory data;
        if(addrToRefers[msg.sender].lvl1 != address(0) && addrToRefers[msg.sender].lvl2 != address(0)){

            (sent, data) = addrToRefers[msg.sender].lvl1.call{value: (msg.value / IdToOrder[orderId].price * 5 / 200)}("");
            require(sent, "Failed to send Ether");
            (sent, data) = addrToRefers[msg.sender].lvl2.call{value: (msg.value / IdToOrder[orderId].price * 5 / 200)}("");
            require(sent, "Failed to send Ether");

        }else if(addrToRefers[msg.sender].lvl1 != address(0)){
            (sent, data) = addrToRefers[msg.sender].lvl1.call{value: (msg.value / IdToOrder[orderId].price * 5 / 200)}("");//questionable is it 2.5 or round(2.5)~3?
            require(sent, "Failed to send Ether");
        }
        _boundedTkn.safeTransfer(msg.sender, msg.value / IdToOrder[orderId].price);
        IdToOrder[orderId].amount -= msg.value / IdToOrder[orderId].price;
        roundInfo.tradesDone += 1;
        roundInfo.ethSpentDurTrade += msg.value;
        emit redeemed(orderId, msg.value / IdToOrder[orderId].price, IdToOrder[orderId].price, IdToOrder[orderId].owner, msg.sender);
        if(IdToOrder[orderId].amount == 0){
            this.removeOrder(orderId);
        }


        

    }

    function startSalePhase() public returns(uint256, uint256) {
        require(roundInfo.endTime < block.timestamp, "previous phase is still active");
        require(roundInfo.nextPhase == Phase.Sale, "Next phase is not sale");
        //delete all orders

        //require(roundInfo.tradesDone > 0);
        if(roundInfo.tradesDone > 0){
            this.removeAllOrders();

        console.log(roundInfo.ethSpentDurTrade);
        if (roundInfo.init == false){
            roundInfo.currentPriceForSale =roundInfo.currentPriceForSale * 103 / 100 + (4 * 1e11);
            roundInfo.amountToMint = roundInfo.ethSpentDurTrade / roundInfo.currentPriceForSale;
            
        }else{
            roundInfo.init = false;

        }
        _boundedTkn.burn(address(this), roundInfo.amountToBurn);
        _boundedTkn.mint(address(this), roundInfo.amountToMint);
        roundInfo.tradesDone = 0;
        roundInfo.endTime = block.timestamp + roundTime * 1 days;
        roundInfo.nextPhase = Phase.Trade;
        roundInfo.tknBoughtDurSale = 0;
        roundInfo.ethSpentDurTrade = 0;
        console.log(roundInfo.amountToMint);
        console.log(roundInfo.currentPriceForSale);

        }else{
            roundInfo.endTime = block.timestamp + roundTime * 1 days;

        }




        return (roundInfo.currentPriceForSale, roundInfo.amountToMint);
    }
    
    function startTradePhase() public {
        require(roundInfo.endTime < block.timestamp, "previous phase is still active");
        require(roundInfo.nextPhase == Phase.Trade, "Next phase is not trade");
        roundInfo.endTime = block.timestamp + roundTime * 1 days;
        roundInfo.nextPhase = Phase.Sale;
        roundInfo.amountToBurn = roundInfo.amountToMint - roundInfo.tknBoughtDurSale;
    }

    function buyTokens() external payable nonReentrant{
        bool sent;
        bytes memory data;
        require(msg.value / roundInfo.currentPriceForSale + roundInfo.tknBoughtDurSale <= roundInfo.amountToMint, "Not enough tkn supply");
        require(roundInfo.nextPhase == Phase.Trade, "Current phase is not Sale");


        if(addrToRefers[msg.sender].lvl1 != address(0) && addrToRefers[msg.sender].lvl2 != address(0)){

            (sent, data) = addrToRefers[msg.sender].lvl1.call{value: (msg.value / roundInfo.currentPriceForSale * 5 / 100)}("");
            require(sent, "Failed to send Ether");
            (sent, data) = addrToRefers[msg.sender].lvl2.call{value: (msg.value / roundInfo.currentPriceForSale * 3 / 100)}("");
            require(sent, "Failed to send Ether");

        }else if(addrToRefers[msg.sender].lvl1 != address(0)){
            (sent, data) = addrToRefers[msg.sender].lvl1.call{value: (msg.value / roundInfo.currentPriceForSale * 5 / 100)}("");
            require(sent, "Failed to send Ether");
        }
        _boundedTkn.safeTransfer(msg.sender, msg.value / roundInfo.currentPriceForSale);
        roundInfo.tknBoughtDurSale += (msg.value / roundInfo.currentPriceForSale);

        emit tknBoughtOnSale(msg.value / roundInfo.currentPriceForSale, msg.sender);
        if(roundInfo.amountToMint == roundInfo.tknBoughtDurSale){
            roundInfo.endTime = block.timestamp;
            emit soldOut(roundInfo.endTime);
        }
    }
    
    function removeAllOrders() public{
        require(msg.sender == address(this), "revert test");

        while(theHeadOfOrders != 0){
            this.removeOrder(IdToOrder[0].pointTo);
        }
    }

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    
}
