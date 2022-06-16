//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceAddress;

    constructor(string memory name, string memory symbol, address _marketplaceAddress) ERC721(name, symbol) {
        marketplaceAddress = _marketplaceAddress;
    }

    function createToken(string memory tokenURI) public returns(uint) {
        uint newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(marketplaceAddress, true);

        _tokenIds.increment();
        return newItemId;
    }

    function createMultipleTokens(uint256 count, string memory tokenURI) public returns(uint[] memory) {
        uint[] memory newItemIds = new uint[](count);
        for (uint i = 0; i < count; i++) {
            newItemIds[i] = createToken(tokenURI);
        }
        return newItemIds;
    }
}