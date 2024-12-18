// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/MetadataManager.sol";
import "../src/libraries/MetadataLib.sol";

contract TestMetadataManager is Test {
    MetadataManager metadataManager;
    MetadataLib.Metadata metadata;

    event MetadataValidated(
        string title,
        string author,
        string contentLink,
        uint256 price,
        string license,
        uint256 copyNumber,
        uint256 totalCopies
    );

    function setUp() public {
        metadataManager = new MetadataManager();
        metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });
    }

    function testValidateAndLogValidInput() public {
        vm.expectEmit(true, true, true, true);
        emit MetadataValidated(
            metadata.title,
            metadata.author,
            metadata.contentLink,
            metadata.price,
            metadata.license,
            metadata.copyNumber,
            metadata.totalCopies
        );

        bool isValid = metadataManager.validateAndLog(metadata);
        assertTrue(isValid);
    }

    function testValidateAndLogInvalidTitle() public {
        metadata.title = "";
        vm.expectRevert(abi.encodeWithSelector(MetadataLib.EmptyField.selector, "title"));
        metadataManager.validateAndLog(metadata);
    }
}
