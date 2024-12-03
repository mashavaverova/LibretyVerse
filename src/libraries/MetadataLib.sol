// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

library MetadataLib {
    using Strings for uint256;

    struct Metadata {
        string title;
        string author;
        string contentLink;
        uint256 price;
        string license;
        uint256 copyNumber;
        uint256 totalCopies;
    }

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
            return ("title", "Title is required");
        }
        if (bytes(metadata.author).length == 0) {
            return ("author", "Author is required");
        }
        if (!isValidURI(metadata.contentLink)) {
            return ("contentLink", "Invalid URI format");
        }
        if (metadata.price == 0) {
            return ("price", "Price must be greater than zero");
        }
        if (metadata.totalCopies == 0) {
            return ("totalCopies", "Total copies must be greater than zero");
        }
        if (metadata.copyNumber > metadata.totalCopies) {
            return ("copyNumber", "Copy number exceeds total copies");
        }
        return ("", ""); // No errors
    }

    /// @notice Checks if a string is a valid URI.
    /// @param uri The URI string to validate.
    /// @return True if the URI is valid, false otherwise.
    function isValidURI(string memory uri) internal pure returns (bool) {
        bytes memory uriBytes = bytes(uri);
        if (uriBytes.length < 8) return false;
        return (
            (uriBytes[0] == 'h' &&
                uriBytes[1] == 't' &&
                uriBytes[2] == 't' &&
                uriBytes[3] == 'p' &&
                uriBytes[4] == ':' &&
                uriBytes[5] == '/' &&
                uriBytes[6] == '/') &&
            (uriBytes[7] == '/' || uriBytes[7] == 's') // Allow "http://" or "https://"
        );
    }

    /// @notice Formats metadata as a JSON-like string for external systems.
    /// @param metadata The metadata to format.
    /// @return A JSON-like string representation of the metadata.
    function formatMetadata(Metadata memory metadata) internal pure returns (string memory) {
        return string(
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
