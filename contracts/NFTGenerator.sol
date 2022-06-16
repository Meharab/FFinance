//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NFT.sol";

contract NFTGenerator {
    mapping(address => address[]) public userNFTs;
    event NFTCreated(address _nft);
    address marketplaceAddress;

    constructor(address _marketplaceAddress) {
        marketplaceAddress = _marketplaceAddress;
    }

    function createNFTCollection(
        string memory name,
        string memory symbol
    ) public {
        NFT nft = new NFT(
            name,
            symbol,
            marketplaceAddress
        );
        userNFTs[msg.sender].push(address(nft));
        emit NFTCreated(address(nft));
    }

    // Get tokens by a user
    function getTokens() public view returns (address[] memory userTokens) {
        userTokens = userNFTs[msg.sender];
    }
}