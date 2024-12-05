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
    
    uint256 public maxMintLimit;
    mapping(uint256 => uint256) public tokenMintCount;
    uint256 public mintPrice;

    mapping(uint256 => string) public tokenIdToCastId;

    event MintLimitUpdated(uint256 newLimit);
    event MintPriceUpdated(uint256 newPrice);
    event PaymentWithdrawn(address to, uint256 amount);

    constructor(
        bytes32 _seed,
        uint256 _initialMintLimit,
        uint256 _initialMintPrice
    ) ERC1155("") Ownable(msg.sender) {
        seed = _seed;
        maxMintLimit = _initialMintLimit;
        mintPrice = _initialMintPrice;
    }

    function setMintLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxMintLimit, "New limit below current max limit");
        maxMintLimit = newLimit;
        emit MintLimitUpdated(newLimit);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    function withdrawPayments(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit PaymentWithdrawn(to, balance);
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

    function generateTokenId(string memory castId) external returns (uint256) {
        uint256 tokenId = computeTokenId(castId);
        require(bytes(tokenIdToCastId[tokenId]).length == 0, "Token ID already minted");

        tokenIdToCastId[tokenId] = castId;

        return tokenId;
    }

    function mint(address to, uint256 tokenId, uint256 quantity) external payable {
        require(quantity > 0, "Quantity must be positive");
        require(msg.value >= mintPrice * quantity, "Insufficient payment");
        
        string memory castId = tokenIdToCastId[tokenId];
        require(bytes(castId).length != 0, "Token ID not minted");
        
        uint256 newMintCount = tokenMintCount[tokenId] + quantity;
        require(newMintCount <= maxMintLimit, "Mint limit reached for token");
        tokenMintCount[tokenId] = newMintCount;
        
        // Calculate and refund excess payment
        uint256 requiredPayment = mintPrice * quantity;
        uint256 excess = msg.value - requiredPayment;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "Refund failed");
        }
    
        _mint(to, tokenId, quantity, "");
    }

    function getTokenMintCount(uint256 tokenId) external view returns (uint256) {
        return tokenMintCount[tokenId];
    }
}
