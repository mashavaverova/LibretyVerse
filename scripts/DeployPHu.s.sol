// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/utility/PaymentHandler.sol";

contract DeployPHu is Script {
    function run() external {
        vm.startBroadcast();

        // Define the addresses of dependencies
        address royaltyManagerAddress = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9; 
        address authorManagerAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3; 
        address platformAdminAddress = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9; 
        address contentAccessAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512; 

        // Deploy the PaymentHandler contract
        PaymentHandler paymentHandler = new PaymentHandler(
            royaltyManagerAddress,
            authorManagerAddress,
            platformAdminAddress,
            contentAccessAddress
        );

        console.log("PaymentHandler deployed to:", address(paymentHandler));

        vm.stopBroadcast();
    }
}
