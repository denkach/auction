const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {ethers} = require("hardhat");

describe("Auction", () => {
  let owner;
  let seller;
  let buyer;
  let auction;

  beforeEach(async () => {
    [owner, seller, buyer] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory("Auction", owner);
    auction = await Auction.deploy();
    await auction.waitForDeployment();
  });

  it("sets owner", async () => {
    const currentOwner = await auction.owner();
    expect(currentOwner).to.eq(owner.address);
  });

  const getTimestamp = async (bn) => {
    return (
      await ethers.provider.getBlock(bn)
    ).timestamp;
  }

  const delay = (ms) => new Promise((resolve) => {
     setTimeout(resolve, ms)
  });

  describe("createAuction", () => {
    it("creates auction correctly", async () => {
      const duration = 60;
      const tx = await auction.createAuction(
        ethers.parseEther("0.0001"),
        3,
        duration,
        "fake item",
      );

      const currentAuction = await auction.auctions(0);
      expect(currentAuction.item).to.eq("fake item");

      const ts = await getTimestamp(tx.blockNumber);
      expect(currentAuction.endsAt).to.eq(ts + duration);
  }); 
});

  describe("buy", () => {
    const duration = 60;
    it("allows to buy", async function () {
      await auction.connect(seller).createAuction(
        ethers.parseEther("0.0001"),
        3,
        duration,
        "fake item",
      );

      this.timeout(5000); //ms
      delay(1000);

      const buyTx = await auction.connect(buyer).
        buy(0, { value: ethers.parseEther("0.0001") });

      const currentAuction = await auction.auctions(0);
      const finalPrice  = Number(currentAuction.finalPrice);

      // await expect(() => buyTx).to.changeEtherBalance(
      //   seller, finalPrice - Math.floor((finalPrice * 10) / 100)
      // );
      await expect(buyTx).to.emit(auction, "AuctionEnded").withArgs(0, finalPrice, buyer.address);
      await expect(auction.connect(buyer).
        buy(0, { value: ethers.parseEther("0.0001") })
      ).to.be.revertedWith('not started or already ended.');
    });
  });
});



