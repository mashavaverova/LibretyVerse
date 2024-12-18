// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/RoyaltyManager.sol";
import "../src/interfaces/IPlatformAdmin.sol";
import "../src/interfaces/IAuthorManager.sol";

contract RoyaltyManagerTest is Test {
    RoyaltyManager royaltyManager;
    IPlatformAdmin platformAdmin;
    IAuthorManager authorManager;

    address platformAdminAddress = address(0x123); // Mock PlatformAdmin
    address authorManagerAddress = address(0x456); // Mock AuthorManager
    address author = address(0xAAA);
    address platform = address(0x789);

    event RoyaltiesCalculated(
        uint256 salePrice,
        uint256 authorShare,
        uint256 platformShare,
        uint256 totalDonations
    );
    event SecondaryRoyaltiesCalculated(
        uint256 salePrice,
        uint256 authorRoyalty,
        uint256 platformRoyalty
    );
    event FeesUpdated(uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty);

    receive() external payable {}

    function setUp() public {
        console.log("---- Setting up RoyaltyManager Test ----");
        platformAdmin = IPlatformAdmin(platformAdminAddress);
        authorManager = IAuthorManager(authorManagerAddress);

        // Deploy the contract
        royaltyManager = new RoyaltyManager(
            platformAdminAddress,
            authorManagerAddress,
            80, // authorFee
            20, // platformFee
            10  // secondaryRoyalty
        );

        console.log("RoyaltyManager contract deployed.");
    }

    function testConstructorConfiguration() public view {
        // Verify initial fees
        (uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty) = royaltyManager.getRoyaltyConfig();

        assertEq(authorFee, 80, "Author fee should be 80%");
        assertEq(platformFee, 20, "Platform fee should be 20%");
        assertEq(secondaryRoyalty, 10, "Secondary royalty should be 10%");
    }

    function testSetFees() public {
        // Only PlatformAdmin should call this function
        vm.prank(platformAdminAddress);
        royaltyManager.setFees(50, 50, 5);

        (uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty) = royaltyManager.getRoyaltyConfig();

        assertEq(authorFee, 50, "Author fee should be 50%");
        assertEq(platformFee, 50, "Platform fee should be 50%");
        assertEq(secondaryRoyalty, 5, "Secondary royalty should be 5%");
    }

    function testUpdatePlatformDonationFee() public {
        vm.prank(platformAdminAddress);
        royaltyManager.updatePlatformDonationFee(25);

        assertEq(royaltyManager.platformDonationFee(), 25, "Platform donation fee should be 25%");
    }

    function testCalculateSecondaryRoyalties() public view{
        uint256 salePrice = 100 ether;
    

        (uint256 authorRoyalty, uint256 platformRoyalty) = royaltyManager.calculateSecondaryRoyalties(salePrice);

        assertEq(authorRoyalty, 10 ether, "Author royalty should be 10% of sale price");
        assertEq(platformRoyalty, 10 ether, "Platform royalty should be 10% of sale price");
    }

    function testDistributeSecondarySale() public {
        uint256 salePrice = 200 ether;

        // Mock author validation
        vm.mockCall(platformAdminAddress, abi.encodeWithSelector(IPlatformAdmin.getValidAuthor.selector), abi.encode(author));

        // Fund the contract
        vm.deal(address(royaltyManager), salePrice);

        // Expect the emit event
        vm.expectEmit(true, true, true, true);
        emit SecondaryRoyaltiesCalculated(salePrice, 20 ether, 20 ether);

        vm.prank(address(this));
        royaltyManager.distributeSecondarySale{value: salePrice}(salePrice, author);

        // Verify balances
        assertEq(author.balance, 20 ether, "Author should receive 10% of secondary sale");
        assertEq(platformAdminAddress.balance, 20 ether, "Platform should receive 10% of secondary sale");
    }
    
    function testSetFeesInvalidSum() public {
        vm.prank(platformAdminAddress);
        vm.expectRevert("Fees must sum to 100%");
        royaltyManager.setFees(60, 50, 5); // Sum is not 100
    }

    function testDistributePrimarySaleZeroPrice() public {
        uint256 salePrice = 0;

        vm.expectRevert("Invalid sale price");
        royaltyManager.distributePrimarySale{value: salePrice}(salePrice, author);
    }
    function testDistributeSecondarySaleZeroPrice() public {
        vm.expectRevert("Invalid sale price");
        royaltyManager.distributeSecondarySale(0, author);
    }
    function testDistributePrimarySaleNoDonations() public {
        uint256 salePrice = 100 ether;
        // Mock the valid author address
        vm.mockCall(
            platformAdminAddress,
            abi.encodeWithSelector(IPlatformAdmin.getValidAuthor.selector),
            abi.encode(author)
        );

        // Mock no donation targets for the author
        vm.mockCall(
            address(authorManager),
            abi.encodeWithSelector(IAuthorManager.getAuthorDonationTargets.selector, author),
            abi.encode(new address[](0), new uint256[](0))  
        );
    
        // Mock platform donation targets to avoid reverts
        vm.mockCall(
            address(platformAdmin),
            abi.encodeWithSelector(IPlatformAdmin.getPlatformDonationTargets.selector),
            abi.encode(new address[](0) , new uint256[](0)) 
        );

        // Fund the contract
        vm.deal(address(royaltyManager), salePrice);
        // Calculate expected shares
        uint256 expectedAuthorShare = (salePrice * 80) / 100; // 80% of sale price
        uint256 expectedPlatformShare = (salePrice * 20) / 100; // 20% of sale price
        // Expect the correct event
        vm.expectEmit(true, true, true, true);
        emit RoyaltiesCalculated(salePrice, expectedAuthorShare, expectedPlatformShare, 0);
        // Call the function
        vm.prank(address(this));
        royaltyManager.distributePrimarySale{value: salePrice}(salePrice, author);
        assertEq(author.balance, expectedAuthorShare, "Incorrect author share after distribution.");
        assertEq(platformAdminAddress.balance, expectedPlatformShare, "Incorrect platform share after distribution.");

    }

    function testDistributePrimarySaleInvalidDonations() public {
        uint256 salePrice = 100 ether;

        // Mock valid author address
        vm.mockCall(
            platformAdminAddress,
            abi.encodeWithSelector(IPlatformAdmin.getValidAuthor.selector),
            abi.encode(author)
        );

        // Mock donation targets with invalid percentages (sum > 100)
        address[] memory targets = new address[](2);
        targets[0] = address(0x111);
        targets[1] = address(0x222);

        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 60; // 60%
        percentages[1] = 50; // 50% (Total = 110%)

        vm.mockCall(
            address(authorManager),
            abi.encodeWithSelector(IAuthorManager.getAuthorDonationTargets.selector, author),
            abi.encode(targets, percentages)
        );

        vm.deal(address(royaltyManager), salePrice);

        // Expect a revert
        vm.expectRevert();
        royaltyManager.distributePrimarySale{value: salePrice}(salePrice, author);
    }

    function testDistributePrimarySaleInsufficientBalance() public {
        uint256 salePrice = 100 ether;

        // Mock valid author address
        vm.mockCall(
            platformAdminAddress,
            abi.encodeWithSelector(IPlatformAdmin.getValidAuthor.selector),
            abi.encode(author)
        );

        // Fund the contract with insufficient balance (e.g., 50 ether)
        vm.deal(address(royaltyManager), 50 ether);

        // Expect a revert due to insufficient balance
        vm.expectRevert();
        royaltyManager.distributePrimarySale{value: salePrice}(salePrice, author);
    }

}
