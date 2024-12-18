// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/MetadataLib.sol";

contract MetadataLibTest is Test {
    using MetadataLib for MetadataLib.Metadata;

    /// @notice Tests valid metadata passes validation.
    function testValidateMetadataValidInput() public pure {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        // Validate metadata
        (string memory field, string memory reason) = metadata.validateMetadata();

        // Assertions
        assertEq(bytes(field).length, 0, string(abi.encodePacked("Field should be empty for valid metadata: ", field)));
        assertEq(
            bytes(reason).length, 0, string(abi.encodePacked("Reason should be empty for valid metadata: ", reason))
        );
    }

    /// @notice Tests missing title validation.
    function testValidateMetadataMissingTitle() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        vm.expectRevert(abi.encodeWithSelector(MetadataLib.EmptyField.selector, "title"));
        metadata.validateMetadata();
    }

    /// @notice Tests missing author validation.
    /// @notice Tests validation failure with missing author.
    function testValidateMetadataMissingAuthor() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        vm.expectRevert(abi.encodeWithSelector(MetadataLib.EmptyField.selector, "author"));
        metadata.validateMetadata();
    }

    /// @notice Tests invalid content link validation.
    /// @notice Tests validation failure with invalid content link.
    function testValidateMetadataInvalidContentLink() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "invalid_uri",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        vm.expectRevert(abi.encodeWithSelector(MetadataLib.InvalidURI.selector, "invalid_uri"));
        metadata.validateMetadata();
    }

    /// @notice Tests zero price validation.
    /// @notice Tests validation failure with zero price.
    function testValidateMetadataZeroPrice() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 0,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        vm.expectRevert(MetadataLib.InvalidPrice.selector);
        metadata.validateMetadata();
    }

    function testValidateMetadataZeroTotalCopies() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 0
        });

        vm.expectRevert(abi.encodeWithSelector(MetadataLib.EmptyField.selector, "totalCopies"));
        metadata.validateMetadata();
    }

    function testValidateMetadataInvalidCopyNumber() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 101,
            totalCopies: 100
        });

        vm.expectRevert(abi.encodeWithSelector(MetadataLib.InvalidCopyNumber.selector, 101, 100));
        metadata.validateMetadata();
    }

    /// @notice Tests formatting of valid metadata into JSON-like string.
    function testFormatMetadataValidInput() public pure {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        // Format metadata
        string memory formatted = metadata.formatMetadata();

        // Expected JSON output
        string memory expected = string(
            abi.encodePacked(
                "{",
                '"title":"Valid Title",',
                '"author":"Valid Author",',
                '"contentLink":"http://example.com",',
                '"price":',
                "1000000000000000000",
                ",", // 1 ether in wei
                '"license":"Creative Commons",',
                '"copyNumber":1,',
                '"totalCopies":100',
                "}"
            )
        );

        // Assertions
        assertEq(formatted, expected, "Formatted metadata should match expected JSON");
    }

    //!!  TODO !!
    /*
    /// @notice Tests edge cases for isValidURI.
    function testIsValidURI() public pure {
    // Valid URIs
        assertTrue(MetadataLib.isValidURI("http://a"), "URI 'http://a' should be valid");
        assertTrue(MetadataLib.isValidURI("https://example.com"), "URI 'https://example.com' should be valid");
        assertTrue(MetadataLib.isValidURI("https://127.0.0.1"), "URI 'https://127.0.0.1' should be valid");
        assertTrue(MetadataLib.isValidURI("http://localhost:8080"), "URI 'http://localhost:8080' should be valid");
        assertTrue(MetadataLib.isValidURI("https://sub.example.com"), "URI 'https://sub.example.com' should be valid");

        // Invalid URIs
        assertFalse(MetadataLib.isValidURI(""), "Empty URI should be invalid");
        assertFalse(MetadataLib.isValidURI("http://"), "URI with only protocol should be invalid");
        assertFalse(MetadataLib.isValidURI("ftp://example.com"), "Invalid protocol 'ftp' should be invalid");
        assertFalse(MetadataLib.isValidURI("https:///example.com"), "Malformed URI with extra slash should be invalid");
        assertFalse(MetadataLib.isValidURI("http:/example.com"), "URI with missing slash should be invalid");
        assertFalse(MetadataLib.isValidURI("example.com"), "URI without protocol should be invalid");
        assertFalse(MetadataLib.isValidURI("https://"), "URI with protocol but no domain should be invalid");
    }
    */

    /// @notice Tests metadata with large fields.
    function testValidateMetadataLargeFields() public pure {
        string memory largeString = new string(10000); // Generate a large string of 10,000 characters
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: largeString,
            author: largeString,
            contentLink: "http://example.com",
            price: 1 ether,
            license: largeString,
            copyNumber: 1,
            totalCopies: 100
        });

        (string memory field, string memory reason) = metadata.validateMetadata();
        assertEq(bytes(field).length, 0, "Field should be empty for valid metadata");
        assertEq(bytes(reason).length, 0, "Reason should be empty for valid metadata");
    }

    /// @notice Tests boundary conditions for numbers in metadata.
    function testValidateMetadataNumericEdgeCases() public pure {
        // Copy number lower bound
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "Valid Author",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });
        (string memory field, string memory reason) = metadata.validateMetadata();
        assertEq(bytes(field).length, 0, "Field should be empty for valid metadata");

        // Copy number upper bound
        metadata.copyNumber = 100;
        (field, reason) = metadata.validateMetadata();
        assertEq(bytes(field).length, 0, "Field should be empty for valid metadata");
    }

    /// @notice Tests metadata with special characters in strings.
    function testValidateMetadataSpecialCharacters() public pure {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "!@#$%^&*()",
            author: "!@#$%^&*()",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "Creative Commons",
            copyNumber: 1,
            totalCopies: 100
        });

        (string memory field, string memory reason) = metadata.validateMetadata();
        console.log("Validation failed at field:", field);
        console.log("Reason:", reason);

        assertEq(bytes(field).length, 0, "Field should be empty for valid metadata");
    }

    /// @notice Tests formatting with empty and large metadata fields.
    function testFormatMetadataEdgeCases() public pure {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata({
            title: "Valid Title",
            author: "",
            contentLink: "http://example.com",
            price: 1 ether,
            license: "",
            copyNumber: 1,
            totalCopies: 100
        });

        string memory formatted = metadata.formatMetadata();
        string memory expected = string(
            abi.encodePacked(
                "{",
                '"title":"Valid Title",',
                '"author":"",',
                '"contentLink":"http://example.com",',
                '"price":',
                "1000000000000000000",
                ",", // 1 ether in wei
                '"license":"",',
                '"copyNumber":1,',
                '"totalCopies":100',
                "}"
            )
        );
        assertEq(formatted, expected, "Formatted metadata should match expected JSON");
    }
}
