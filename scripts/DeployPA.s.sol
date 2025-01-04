// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/core/PlatformAdmin.sol";
 
contract DeployPA is Script {
    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions
        PlatformAdmin platformAdmin = new PlatformAdmin();
        console.log("PlatformAdmin deployed to:", address(platformAdmin));
        vm.stopBroadcast(); // Stop broadcasting
    }
}


