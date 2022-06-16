//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    mapping(uint256 => CreatorStruct) public tokenToCreatorStruct;

    uint256 listingPrice = 1; //0.0025 ether;

    enum Categories { ARTS, BUSINESS, COLLECTIBLES }

    struct CreatorStruct {
        address payable creator;
        uint royalty;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        Categories categories;
    }

    mapping(uint256 => MarketItem) private _idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        Categories category
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function updateListingPrice(uint256 _amount) external {
        listingPrice = _amount;
    }

    function transferNFT(uint256 id, address to) public {
        MarketItem storage marketItem = _idToMarketItem[id];
        require(
            marketItem.owner == address(msg.sender) ||
                address(msg.sender) ==
                IERC721(marketItem.nftContract).ownerOf(marketItem.tokenId)
        );
        if (marketItem.owner == address(msg.sender)) {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(this),
                to,
                marketItem.tokenId,
                ""
            );
            marketItem.owner = payable(to);
            marketItem.sold = true;
        } else {
            IERC721(marketItem.nftContract).safeTransferFrom(
                address(msg.sender),
                to,
                marketItem.tokenId,
                ""
            );
        }
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        Categories _category,
        uint royalty
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        /*require(
            msg.value >= listingPrice,
            "msg.value must be equal greater than listing price"
        );*/
        require(royalty <= 10, "Royalty must be less than or equal to 10%");

        uint256 itemId = _itemIds.current();

        if (tokenToCreatorStruct[tokenId].creator == address(0)) {
            tokenToCreatorStruct[tokenId].creator = payable(msg.sender);
            tokenToCreatorStruct[tokenId].royalty = royalty;
        }

        _idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            _category
        );

        _itemIds.increment();
        payable(owner()).transfer(msg.value); //listing price sent

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            _category
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        MarketItem storage marketItem = _idToMarketItem[itemId];
        /*require(
            msg.value >= marketItem.price,
            "msg.value must be equal greater than price"
        );*/
        require(
            address(this) == IERC721(nftContract).ownerOf(marketItem.tokenId),
            "Item is not listed in the marketplace"
        );

        marketItem.owner = payable(msg.sender);
        marketItem.sold = true;

        uint256 royaltyFee = (msg.value * tokenToCreatorStruct[marketItem.tokenId].royalty) / 100;
        marketItem.seller.transfer(msg.value - (2 * royaltyFee));
        tokenToCreatorStruct[marketItem.tokenId].creator.transfer(royaltyFee);

        payable(owner()).transfer(royaltyFee);
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            marketItem.tokenId
        );
        _itemsSold.increment();

        emit MarketItemSold(
            itemId,
            nftContract,
            marketItem.tokenId,
            marketItem.seller,
            msg.sender,
            msg.value
        );
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        MarketItem[] memory marketItems = new MarketItem[](
            _itemIds.current() - _itemsSold.current()
        );
        uint256 index = 0;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (!marketItem.sold && marketItem.owner == address(0)) {
                marketItems[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }
        return marketItems;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 index = 0;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (
                marketItem.owner == address(msg.sender) ||
                address(msg.sender) ==
                IERC721(marketItem.nftContract).ownerOf(marketItem.tokenId)
            ) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (marketItem.owner == address(msg.sender)) {
                items[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }

        return items;
    }

    function fetchNFTsCreated() public view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 index;

        for (uint256 i = 0; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (marketItem.seller == address(msg.sender)) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i; i < _itemIds.current(); i++) {
            MarketItem memory marketItem = _idToMarketItem[i];
            if (marketItem.seller == address(msg.sender)) {
                items[index] = _idToMarketItem[marketItem.itemId];
                index++;
            }
        }

        return items;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}