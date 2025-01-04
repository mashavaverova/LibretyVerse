// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/core/ContentAccess.sol";
 
contract DeployCA is Script {
    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions
        ContentAccess contentAccess = new ContentAccess();
        console.log("ContentAccess deployed to:", address(contentAccess));
        vm.stopBroadcast(); // Stop broadcasting
    }
}


