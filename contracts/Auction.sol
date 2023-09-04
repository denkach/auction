// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Auction {
    address public owner;
    uint constant DURATION = 2 days; // 2 * 24 * 60 * 60
    uint constant FEE = 10; 

    struct AuctionStructure {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint duration;
        uint startsAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool ended;
    }

    AuctionStructure[] public auctions;

    event AuctionCreated(uint index, string itemName, uint startingPrice, uint duration);
    event AuctionEnded(uint index, uint finalPrice, address winner);

    constructor () {
        owner = msg.sender;
    }

    function createAuction(uint _startingPrice, uint _discountRate, uint _duration, string calldata _item) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(_startingPrice >= duration * _discountRate, "incorrect starting price");

        AuctionStructure memory auction = AuctionStructure({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            duration: duration,
            startsAt: block.timestamp, // now
            endsAt: block.timestamp + duration,
            discountRate: _discountRate,
            item: _item,
            ended: false
        });

        auctions.push(auction);

        emit AuctionCreated(auctions.length - 1, _item, _startingPrice, duration);
    }

    function getPriceFor(uint _index) public view returns(uint) {
        AuctionStructure memory currentAuction = auctions[_index];
        require(!currentAuction.ended, "ended!");

        uint elapsed = block.timestamp - currentAuction.startsAt;
        uint discount = currentAuction.discountRate * elapsed;

        return currentAuction.startingPrice - discount;
    }

    function buy(uint _index) external payable {
        AuctionStructure storage currentAuction = auctions[_index];
        require (block.timestamp < currentAuction.endsAt && !currentAuction.ended, "not started or already ended.");
        uint currentPrice = getPriceFor(_index);
        require(msg.value >= currentPrice);
        currentAuction.finalPrice = currentPrice;
        currentAuction.ended = true;
        uint refund = msg.value - currentPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        currentAuction.seller.transfer(currentPrice - ((currentPrice + FEE) / 100));

        emit AuctionEnded(_index, currentPrice, msg.sender);
    }
}
