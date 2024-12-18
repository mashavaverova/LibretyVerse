// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/RoyaltyLib.sol";

contract TestRoyaltyLib is Test {
    function testValidRoyaltyConfiguration() public pure {
        uint256 salePrice = 1000;
        uint256 authorFee = 50;
        uint256 platformFee = 30;
        uint256 donationFee = 20;

        (uint256 authorRoyalty, uint256 platformRoyalty, uint256 donationRoyalty) =
            RoyaltyLib.calculateRoyalties(salePrice, authorFee, platformFee, donationFee);

        assertEq(authorRoyalty, 500, "Author royalty is incorrect");
        assertEq(platformRoyalty, 300, "Platform royalty is incorrect");
        assertEq(donationRoyalty, 200, "Donation royalty is incorrect");
    }

    function testSinglePartyGetsAll() public pure {
        uint256 salePrice = 1000;
        uint256 authorFee = 100;
        uint256 platformFee = 0;
        uint256 donationFee = 0;

        (uint256 authorRoyalty, uint256 platformRoyalty, uint256 donationRoyalty) =
            RoyaltyLib.calculateRoyalties(salePrice, authorFee, platformFee, donationFee);

        assertEq(authorRoyalty, 1000, "Author royalty is incorrect");
        assertEq(platformRoyalty, 0, "Platform royalty is incorrect");
        assertEq(donationRoyalty, 0, "Donation royalty is incorrect");
    }

    function testInvalidFeeSumReverts() public {
        uint256 salePrice = 1000;
        uint256 authorFee = 60;
        uint256 platformFee = 30;
        uint256 donationFee = 20;

        vm.expectRevert(abi.encodeWithSelector(RoyaltyLib.InvalidFeeConfiguration.selector, "Fees must sum to 100%"));

        RoyaltyLib.calculateRoyalties(salePrice, authorFee, platformFee, donationFee);
    }

    function testIndividualFeeExceeds100Reverts() public {
        uint256 salePrice = 1000;
        uint256 authorFee = 101;
        uint256 platformFee = 0;
        uint256 donationFee = 0;

        vm.expectRevert(abi.encodeWithSelector(RoyaltyLib.InvalidFeeConfiguration.selector, "Fees must sum to 100%"));

        RoyaltyLib.calculateRoyalties(salePrice, authorFee, platformFee, donationFee);
    }
}
