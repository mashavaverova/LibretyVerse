// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/core/LibretyNFT.sol";

contract DeployLibrety is Script {
    function run() external {
        // Start the deployment broadcast
        vm.startBroadcast();

        // Replace these addresses with actual deployed contract addresses
        address contentAccessAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        address royaltyManagerAddress = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
        address paymentHandlerAddress = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;

        // Deploy the LibretyNFT contract
        LibretyNFT libretyNFT = new LibretyNFT(
            "LibretyNFT", // Name of the NFT collection
            "LNFT",       // Symbol of the NFT collection
            contentAccessAddress,
            royaltyManagerAddress,
            paymentHandlerAddress
        );

        console.log("LibretyNFT deployed to:", address(libretyNFT));

        // Stop the deployment broadcast
        vm.stopBroadcast();
    }
}
