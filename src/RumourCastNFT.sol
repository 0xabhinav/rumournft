// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RumourCastNFT is ERC1155, Ownable {
    using Strings for uint256;
    
    uint256 public constant SUPPLY_PER_TOKEN = 1000;
    string public baseURI = "rumourcast.xyz/nft/";
    bytes32 public immutable seed;

    constructor(bytes32 _seed) ERC1155("") Ownable(msg.sender) {
        seed = _seed;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".svg"));
    }

    function computeTokenId(string memory castId) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, castId)));
    }

    function mint(address to, string memory castId) external {
        uint256 tokenId = computeTokenId(castId);
        _mint(to, tokenId, SUPPLY_PER_TOKEN, "");
    }
}
