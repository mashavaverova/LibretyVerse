// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/core/AuthorManager.sol";


contract DeployAM is Script {
    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions
        address platformAdmin = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        AuthorManager authorManager = new AuthorManager(platformAdmin);
        console.log("AuthorManager deployed to:", address(authorManager));
        vm.stopBroadcast(); // Stop broadcasting
    }
}
