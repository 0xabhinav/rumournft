// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RumourCastNFT} from "../src/RumourCastNFT.sol";
import {console2} from "forge-std/console2.sol";

contract RumourCastNFTScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get seed from env var, default to "rumourcast" if not provided
        string memory seedStr = vm.envOr("SEED", string("rumourcast"));
        bytes32 seed = keccak256(abi.encodePacked(seedStr));

        vm.startBroadcast(deployerPrivateKey);

        RumourCastNFT nft = new RumourCastNFT(seed);

        vm.stopBroadcast();

        console2.log("RumourCastNFT deployed at:", address(nft));
        console2.log("Seed string used:", seedStr);
        console2.log("Seed bytes32:", uint256(seed));
    }
}