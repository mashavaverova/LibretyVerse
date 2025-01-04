// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/core/RoyaltyManager.sol";

contract DeployRM is Script {
    function run() external {
        vm.startBroadcast();

        // Replace these with actual deployed contract addresses
        address platformAdmin = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9; // PlatformAdmin deployed address
        address authorManager = 0x5FbDB2315678afecb367f032d93F642f64180aa3; // AuthorManager deployed address

        // Royalty configuration
        uint256 authorFee = 50;       // Author gets 50% of primary sales
        uint256 platformFee = 50;    // Platform gets 50% of primary sales
        uint256 secondaryRoyalty = 10; // 10% for secondary sales

        // Deploy RoyaltyManager
        RoyaltyManager royaltyManager = new RoyaltyManager(
            platformAdmin,
            authorManager,
            authorFee,
            platformFee,
            secondaryRoyalty
        );

        console.log("RoyaltyManager deployed to:", address(royaltyManager));

        vm.stopBroadcast();
    }
}
