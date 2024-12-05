// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RumourCastNFT is ERC1155, Ownable {
    using Strings for uint256;
    
    uint256 public constant SUPPLY_PER_TOKEN = 1000;
    string public baseURI = "https://rumourcast.xyz/nft/{id}.json";
    bytes32 public immutable seed;

    // New mapping to store tokenId to castId
    mapping(uint256 => string) public tokenIdToCastId;

    constructor(bytes32 _seed) ERC1155("") Ownable(msg.sender) {
        seed = _seed;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenIdStr = tokenId.toString();
        bytes memory baseURIBytes = bytes(baseURI);
        
        uint256 i = 0;

        while (i < baseURIBytes.length - 3) {
            if (i + 4 <= baseURIBytes.length &&
                baseURIBytes[i] == '{' &&
                baseURIBytes[i+1] == 'i' &&
                baseURIBytes[i+2] == 'd' &&
                baseURIBytes[i+3] == '}') {
                    return string(abi.encodePacked(
                        substring(baseURI, 0, i),
                        tokenIdStr,
                        substring(baseURI, i + 4, baseURIBytes.length)
                    ));
            }
            i++;
        }
        
        // If no {id} pattern found, append tokenId at the end
        return string(abi.encodePacked(baseURI, tokenIdStr));
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for(uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getCastId(uint256 tokenId) public view returns (string memory) {
        string memory castId = tokenIdToCastId[tokenId];
        require(bytes(castId).length > 0, "Token ID does not exist");
        return castId;
    }

    function computeTokenId(string memory castId) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, castId)));
    }

    function mint(address to, string memory castId) external {
        uint256 tokenId = computeTokenId(castId);
        require(bytes(tokenIdToCastId[tokenId]).length == 0, "Token ID already minted");
        
        tokenIdToCastId[tokenId] = castId;
        // TODO: Improve minting logic as needed
        _mint(to, tokenId, SUPPLY_PER_TOKEN, "");
    }
}
