// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/// @title MetadataLib
/// @notice Provides utilities for managing and validating metadata.
library MetadataLib {
    using Strings for uint256;

    /// @dev Metadata structure to hold book details.
    struct Metadata {
        string title;
        string author;
        string contentLink;
        uint256 price;
        string license;
        uint256 copyNumber;
        uint256 totalCopies;
    }

    /// @dev Custom error for invalid metadata.
    error InvalidMetadata(string field, string reason);

    /// @notice Validates the metadata structure.
    /// @param metadata The metadata to validate.
    /// @return field The field that failed validation (empty if valid).
    /// @return reason The reason the field failed validation (empty if valid).
    function validateMetadata(Metadata memory metadata)
        internal
        pure
        returns (string memory field, string memory reason)
    {
        if (bytes(metadata.title).length == 0) {
            return ("title", "Title must not be empty");
        }
        if (bytes(metadata.author).length == 0) {
            return ("author", "Author must not be empty");
        }
        if (!isValidURI(metadata.contentLink)) {
            return ("contentLink", "Content link must be a valid URI (http/https)");
        }
        if (metadata.price == 0) {
            return ("price", "Price must be greater than zero");
        }
        if (metadata.totalCopies == 0) {
            return ("totalCopies", "Total copies must be greater than zero");
        }
        if (metadata.copyNumber == 0 || metadata.copyNumber > metadata.totalCopies) {
            return ("copyNumber", "Copy number must be greater than zero and within total copies");
        }
        return ("", ""); // Valid metadata
    }

    /// @notice Checks if a string is a valid URI.
    /// @param uri The URI string to validate.
    /// @return isValid True if the URI is valid, false otherwise.
    function isValidURI(string memory uri) internal pure returns (bool isValid) {
        bytes memory uriBytes = bytes(uri);
        if (uriBytes.length < 8) return false; // Minimum length for valid URI

        // Check for "http://" or "https://"
        if (
            uriBytes[0] == 'h' &&
            uriBytes[1] == 't' &&
            uriBytes[2] == 't' &&
            uriBytes[3] == 'p' &&
            uriBytes[4] == ':' &&
            uriBytes[5] == '/' &&
            uriBytes[6] == '/' &&
            (uriBytes[7] == '/' || uriBytes[7] == 's')
        ) {
            return true;
        }
        return false;
    }

    /// @notice Formats metadata as a JSON-like string for external systems.
    /// @param metadata The metadata to format.
    /// @return formattedMetadata A JSON-like string representation of the metadata.
    function formatMetadata(Metadata memory metadata) internal pure returns (string memory formattedMetadata) {
        formattedMetadata = string(
            abi.encodePacked(
                "{",
                '"title":"', metadata.title, '",',
                '"author":"', metadata.author, '",',
                '"contentLink":"', metadata.contentLink, '",',
                '"price":', metadata.price.toString(), ',',
                '"license":"', metadata.license, '",',
                '"copyNumber":', metadata.copyNumber.toString(), ',',
                '"totalCopies":', metadata.totalCopies.toString(),
                "}"
            )
        );
    }
}
