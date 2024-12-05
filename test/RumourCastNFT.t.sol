// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RumourCastNFT.sol";

contract RumourCastNFTTest is Test {
    RumourCastNFT public nft;
    bytes32 public constant SEED = bytes32(uint256(1));
    address public constant OWNER = address(1);
    address public constant USER = address(2);

    function setUp() public {
        vm.prank(OWNER);
        nft = new RumourCastNFT(SEED);
    }

    function testMint() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        uint256 expectedTokenId = nft.computeTokenId(castId);

        vm.prank(USER);
        nft.mint(USER, castId);

        assertEq(nft.balanceOf(USER, expectedTokenId), 1000);
    }

    function testURI() public view {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        uint256 tokenId = nft.computeTokenId(castId);
        
        assertEq(
            nft.uri(tokenId),
            string(abi.encodePacked("https://rumourcast.xyz/nft/", vm.toString(tokenId), ".json"))
        );
    }

    function testSetBaseURI() public {
        string memory newBaseURI = "https://new.rumourcast.xyz/nft/{id}/metadata";
        
        vm.prank(OWNER);
        nft.setBaseURI(newBaseURI);
        
        uint256 tokenId = 1;
        assertEq(
            nft.uri(tokenId),
            string(abi.encodePacked("https://new.rumourcast.xyz/nft/", vm.toString(tokenId), "/metadata"))
        );
    }

    function testURIWithCustomPattern() public {
        string memory customURI = "https://api.rumourcast.xyz/metadata/{id}/token";
        
        vm.prank(OWNER);
        nft.setBaseURI(customURI);
        
        uint256 tokenId = 123;
        assertEq(
            nft.uri(tokenId),
            string(abi.encodePacked("https://api.rumourcast.xyz/metadata/", vm.toString(tokenId), "/token"))
        );
    }

    function testMintAndCastIdStorage() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        uint256 expectedTokenId = nft.computeTokenId(castId);

        vm.prank(USER);
        nft.mint(USER, castId);

        assertEq(nft.balanceOf(USER, expectedTokenId), 1000);
        assertEq(nft.getCastId(expectedTokenId), castId);
    }

    function testCannotMintSameCastIdTwice() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        vm.prank(USER);
        nft.mint(USER, castId);

        vm.expectRevert("Token ID already minted");
        vm.prank(USER);
        nft.mint(USER, castId);
    }

    function testGetNonExistentCastId() public {
        uint256 nonExistentTokenId = 999;
        
        vm.expectRevert("Token ID does not exist");
        nft.getCastId(nonExistentTokenId);
    }
} 