// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RumourCastNFT} from "../src/RumourCastNFT.sol";
import {console2} from "forge-std/console2.sol";

contract RumourCastNFTScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get deployment parameters from env vars
        string memory seedStr = vm.envOr("SEED", string("rumourcast"));
        uint256 mintLimit = vm.envOr("MINT_LIMIT", uint256(1000));
        uint256 mintPrice = vm.envOr("MINT_PRICE", uint256(0.1 ether));
        
        bytes32 seed = keccak256(abi.encodePacked(seedStr));

        vm.startBroadcast(deployerPrivateKey);

        RumourCastNFT nft = new RumourCastNFT(
            seed,
            mintLimit,
            mintPrice
        );

        vm.stopBroadcast();

        console2.log("RumourCastNFT deployed at:", address(nft));
        console2.log("Seed string used:", seedStr);
        console2.log("Seed bytes32:", uint256(seed));
        console2.log("Initial mint limit:", mintLimit);
        console2.log("Initial mint price:", mintPrice);
        console2.log("Supply per token:", nft.SUPPLY_PER_TOKEN());
    }
}