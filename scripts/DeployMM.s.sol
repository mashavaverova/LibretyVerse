// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/core/MetadataManager.sol";
 
contract DeployMM is Script {
    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions
        MetadataManager metadataManager = new MetadataManager();
        console.log("MetadataManager deployed to:", address(metadataManager));
        vm.stopBroadcast(); // Stop broadcasting
    }
}


