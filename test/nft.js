
const { expect } = require("chai");

const toWei = (num) => ethers.utils.parseEther(num.toString());
const fromWei = (num) => ethers.utils.formatEther(num);

describe("Contract", function () {

  let NFT;
  let nft;
  let Marketplace;
  let marketplace;
  let Generator;
  let generator;
  let owner;
  let addr1;
  let addr2;
  let addrs;
  let name = "Forge Finance Token";
  let symbol = "FFT";
  let URI = "metadata";

  beforeEach(async function () {
    Marketplace = await ethers.getContractFactory("Marketplace");
    NFT = await ethers.getContractFactory("NFT");
    Generator = await ethers.getContractFactory("NFTGenerator");

    [deployer, addr1, addr2, ...addrs] = await ethers.getSigners();

    marketplace = await Marketplace.deploy();
    nft = await NFT.deploy(name, symbol, marketplace.address);
    generator = await Generator.deploy(marketplace.address);
  });

  describe("NFT", function () {
    it("Should track name and symbol of the nft collection", async function () {
      const nftName = "Forge Finance Token";
      const nftSymbol = "FFT";
      expect(await nft.name()).to.equal(nftName);
      expect(await nft.symbol()).to.equal(nftSymbol);
    });

    it("Should minted NFT", async function () {
      await nft.connect(addr1).createToken(URI);
      expect(await nft.balanceOf(addr1.address)).to.equal(1);
      await nft.connect(addr2).createToken(URI)
      expect(await nft.balanceOf(addr2.address)).to.equal(1);
    });

    it("Should minted multiple NFT", async function () {
      await nft.connect(addr1).createMultipleTokens(3, URI);
      expect(await nft.balanceOf(addr1.address)).to.equal(3);
      expect(await nft.tokenURI(1)).to.equal(URI);
      await nft.connect(addr2).createMultipleTokens(2, URI)
      expect(await nft.balanceOf(addr2.address)).to.equal(2);
      expect(await nft.tokenURI(2)).to.equal(URI);
    });
  });

  describe("NFTGenerator", function () {
    it("Should create NFT collection", async function () {
      await generator.connect(addr1).createNFTCollection(name, symbol);
    });

    it("Should Get tokens by a user", async function () {
      const userTokens = await generator.getTokens();
    });
  });

    describe("Marketplace", async function () {
      let price = 1;
      let updatedPrice = 2;
      let category = 1;
      let itemPrice = 2;
      let zeroAdd = "0x0000000000000000000000000000000000000000";

      beforeEach(async function () {
        await nft.connect(addr1).createToken(URI);
        //await marketplace.connect(addr1).createMarketItem(nft.address, 1 , toWei(price), 1, 5);
      });

      it("Should track listing price of the marketplace", async function () {
        const listingPrice = await marketplace.getListingPrice();
        expect(listingPrice).to.equal(price);
      });

      it("Should track listing price of the marketplace", async function () {
        await marketplace.connect(addr1).updateListingPrice(2);
        const listingPrice = await marketplace.getListingPrice();
        expect(listingPrice).to.equal(updatedPrice);
      });

      it("Should transfer NFT to another address", async function () {
        await nft.connect(addr1).createToken(URI);
        await expect(marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5));
        await marketplace.connect(addr2).createMarketSale(nft.address, 0 )
        await marketplace.connect(addr2).transferNFT(0, addr1.address)
        //expect(await nft.balanceOf(addr1.address)).to.equal(0);
        //expect(await nft.balanceOf(addr2.address)).to.equal(1);
      });

      it("Should created item, transfer NFT from seller to marketplace and emit create event", async function () {
        await nft.connect(addr1).createToken(URI);
        await expect(marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5))
          .to.emit(marketplace, "MarketItemCreated").withArgs(0, nft.address, 1, addr1.address, zeroAdd, toWei(itemPrice), category);
        expect(await nft.ownerOf(1)).to.equal(marketplace.address);
      });

      it("Should created sale, pay seller, transfer NFT to buyer, charge fees and emit a sold event", async function () {
        await nft.connect(addr1).createToken(URI);
        await marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5);
        await expect(marketplace.connect(addr2).createMarketSale(nft.address, 0 ))
          .to.emit(marketplace, "MarketItemSold").withArgs(0, nft.address, 1, zeroAdd, addr2.address, toWei(itemPrice));
        expect(await nft.ownerOf(1)).to.equal(marketplace.address);
      });

      it("Should fetch Market Items", async function () {
        await nft.connect(addr1).createToken(URI);
        await marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5);
        let fetchMarketItems = await marketplace.fetchMarketItems();
        //console.log(fetchMarketItems)
      });

      it("Should fetch My NFTs", async function () {
        await nft.connect(addr1).createToken(URI);
        await marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5);
        let fetchMyNFTs = await marketplace.fetchMyNFTs();
        //console.log(fetchMyNFTs)
      });

      it("Should fetch NFTs Created", async function () {
        await nft.connect(addr1).createToken(URI);
        await marketplace.connect(addr1).createMarketItem(nft.address, 1, toWei(itemPrice), category, 5);
        let fetchNFTsCreated = await marketplace.fetchNFTsCreated();
        //console.log(fetchNFTsCreated)
      });
    });
  });