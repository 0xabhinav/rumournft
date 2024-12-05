// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RumourCastNFT.sol";

contract RumourCastNFTTest is Test {
    RumourCastNFT public nft;
    bytes32 public constant SEED = bytes32(uint256(1));
    address public constant OWNER = address(1);
    address public constant USER = address(2);

    uint256 public constant INITIAL_MINT_LIMIT = 100;
    uint256 public constant INITIAL_MINT_PRICE = 0.1 ether;

    function setUp() public {
        vm.prank(OWNER);
        nft = new RumourCastNFT(
            SEED,
            INITIAL_MINT_LIMIT,
            INITIAL_MINT_PRICE
        );
    }

    function testGenerateTokenId() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        uint256 expectedTokenId = nft.computeTokenId(castId);

        vm.prank(USER);
        uint256 tokenId = nft.generateTokenId(castId);

        assertEq(tokenId, expectedTokenId);
        assertEq(nft.getCastId(tokenId), castId);
    }

    function testCannotGenerateSameTokenIdTwice() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        vm.prank(USER);
        nft.generateTokenId(castId);

        vm.expectRevert("Token ID already minted");
        vm.prank(USER);
        nft.generateTokenId(castId);
    }

    function testMintWithQuantity() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        vm.deal(USER, 1 ether);
        vm.startPrank(USER);
        
        uint256 tokenId = nft.generateTokenId(castId);
        uint256 quantity = 2;
        
        uint256 payment = INITIAL_MINT_PRICE * quantity;
        nft.mint{value: payment}(USER, tokenId, quantity);
        vm.stopPrank();

        assertEq(nft.balanceOf(USER, tokenId), quantity);
        assertEq(nft.getTokenMintCount(tokenId), quantity);
    }

    function testCannotMintNonExistentToken() public {
        uint256 nonExistentTokenId = 999;
        
        vm.deal(USER, 1 ether);
        vm.prank(USER);
        vm.expectRevert("Token ID not minted");
        nft.mint{value: INITIAL_MINT_PRICE}(USER, nonExistentTokenId, 1);
    }

    function testMintWithRefund() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        uint256 quantity = 1;
        uint256 excessPayment = 0.5 ether;
        uint256 totalPayment = INITIAL_MINT_PRICE * quantity + excessPayment;

        vm.deal(USER, 1 ether);
        vm.startPrank(USER);
        
        uint256 tokenId = nft.generateTokenId(castId);
        uint256 userInitialBalance = USER.balance;
        
        nft.mint{value: totalPayment}(USER, tokenId, quantity);
        vm.stopPrank();

        assertEq(USER.balance, userInitialBalance - (INITIAL_MINT_PRICE * quantity));
        assertEq(address(nft).balance, INITIAL_MINT_PRICE * quantity);
    }

    function testMintLimit() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        vm.deal(USER, 100 ether);
        vm.startPrank(USER);
        
        uint256 tokenId = nft.generateTokenId(castId);

        // Mint up to the limit
        nft.mint{value: INITIAL_MINT_PRICE * INITIAL_MINT_LIMIT}(USER, tokenId, INITIAL_MINT_LIMIT);

        // Try to mint one more
        vm.expectRevert("Mint limit reached for token");
        nft.mint{value: INITIAL_MINT_PRICE}(USER, tokenId, 1);
        
        vm.stopPrank();

        assertEq(nft.getTokenMintCount(tokenId), INITIAL_MINT_LIMIT);
    }

    function testPartialMintsThenLimit() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        vm.deal(USER, 100 ether);
        vm.startPrank(USER);
        
        uint256 tokenId = nft.generateTokenId(castId);

        // First mint
        uint256 firstMint = 40;
        nft.mint{value: INITIAL_MINT_PRICE * firstMint}(USER, tokenId, firstMint);
        
        // Second mint
        uint256 secondMint = 30;
        nft.mint{value: INITIAL_MINT_PRICE * secondMint}(USER, tokenId, secondMint);

        // Try to mint more than remaining
        uint256 remainingLimit = INITIAL_MINT_LIMIT - firstMint - secondMint;
        vm.expectRevert("Mint limit reached for token");
        nft.mint{value: INITIAL_MINT_PRICE * (remainingLimit + 1)}(
            USER, 
            tokenId, 
            remainingLimit + 1
        );

        vm.stopPrank();

        assertEq(nft.getTokenMintCount(tokenId), firstMint + secondMint);
    }

    // URI and admin function tests remain unchanged
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

    function testUpdateMintLimit() public {
        uint256 newLimit = 200;
        
        vm.prank(OWNER);
        nft.setMintLimit(newLimit);
        
        assertEq(nft.maxMintLimit(), newLimit);
    }

    function testUpdateMintPrice() public {
        uint256 newPrice = 0.2 ether;
        
        vm.prank(OWNER);
        nft.setMintPrice(newPrice);
        
        assertEq(nft.mintPrice(), newPrice);
    }

    function testWithdrawPayments() public {
        string memory castId = "0x3f1368ec5049c926f2b3b7932abe0398ddf11030";
        
        // First mint something to get some payments
        vm.deal(USER, 1 ether);
        vm.prank(USER);
        uint256 tokenId = nft.generateTokenId(castId);
        
        vm.prank(USER);
        nft.mint{value: INITIAL_MINT_PRICE}(USER, tokenId, 1);

        uint256 initialBalance = address(OWNER).balance;
        
        vm.prank(OWNER);
        nft.withdrawPayments(payable(OWNER));

        assertEq(address(nft).balance, 0);
        assertEq(address(OWNER).balance, initialBalance + INITIAL_MINT_PRICE);
    }
} 