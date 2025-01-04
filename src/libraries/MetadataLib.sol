// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/console.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * @title MetadataLib
 * @dev A library for managing and validating metadata for digital content, including validation and formatting.
 * @notice created by @mashavaverova
 */

library MetadataLib {
    using Strings for uint256;

    /**
     * @notice Represents metadata for digital content.
     * @param title Title of the content.
     * @param author Author of the content.
     * @param contentLink Link to the content (e.g., IPFS or HTTP URL).
     * @param price Price of the content in ETH.
     * @param license License type or information.
     * @param copyNumber Current copy number of the content.
     * @param totalCopies Total number of copies available.
     */
    struct Metadata {
        string title;
        string author;
        string contentLink;
        uint256 price;
        string license;
        uint256 copyNumber;
        uint256 totalCopies;
    }

    /** Custom errors */
    error EmptyField(string field);
    error InvalidURI(string uri);
    error InvalidPrice();
    error InvalidCopyNumber(uint256 copyNumber, uint256 totalCopies);


/* =======================================================
                      Internal Functions
   ======================================================= */

   
    /**
     * @notice Validates metadata fields to ensure they meet basic requirements.
     * @param metadata The metadata to validate.
     * @return field The name of the invalid field, if any.
     * @return reason The reason for the invalidation, if any.
     * @dev Reverts with specific errors for invalid fields.
     */
    function validateMetadata(Metadata memory metadata)
        internal
        pure
        returns (string memory field, string memory reason)
    {
        if (bytes(metadata.title).length == 0) {
            revert EmptyField("title");
        }
        if (bytes(metadata.author).length == 0) {
            revert EmptyField("author");
        }
        if (!isValidURI(metadata.contentLink)) {
            console.log("Invalid URI:", metadata.contentLink);
            revert InvalidURI(metadata.contentLink);
        }
        if (metadata.price == 0) {
            revert InvalidPrice();
        }
        if (metadata.totalCopies == 0) {
            revert EmptyField("totalCopies");
        }
        if (metadata.copyNumber == 0 || metadata.copyNumber > metadata.totalCopies) {
            revert InvalidCopyNumber(metadata.copyNumber, metadata.totalCopies);
        }

        return ("", "");
    }
        /**
     * @notice Checks if a URI is valid. Accepts `http://`, `https://`, or `ipfs://` prefixes.
     * @param uri The URI to validate.
     * @return True if the URI is valid, otherwise false.
     */
    function isValidURI(string memory uri) internal pure returns (bool) {
        bytes memory uriBytes = bytes(uri);

        if (uriBytes.length < 7) return false;

        // Check for http:// or https://
        bool hasHttp = uriBytes.length >= 7 && uriBytes[0] == "h" && uriBytes[1] == "t" && uriBytes[2] == "t"
            && uriBytes[3] == "p" && uriBytes[4] == ":" && uriBytes[5] == "/" && uriBytes[6] == "/";

        bool hasHttps = uriBytes.length >= 8 && hasHttp && uriBytes[7] == "s";

        // Check for ipfs://
        bool hasIpfs = uriBytes.length >= 7 && uriBytes[0] == "i" && uriBytes[1] == "p" && uriBytes[2] == "f"
            && uriBytes[3] == "s" && uriBytes[4] == ":" && uriBytes[5] == "/" && uriBytes[6] == "/";

        return hasHttp || hasHttps || hasIpfs;
    }


    /**
     * @notice Formats metadata into a JSON-like string.
     * @param metadata The metadata to format.
     * @return formattedMetadata The metadata as a JSON-like string.
     */
    function formatMetadata(Metadata memory metadata) internal pure returns (string memory formattedMetadata) {
    formattedMetadata = string(
        bytes.concat(
            "{",
            '"title":"',
            bytes(metadata.title),
            '",',
            '"author":"',
            bytes(metadata.author),
            '",',
            '"contentLink":"',
            bytes(metadata.contentLink),
            '",',
            '"price":',
            bytes(metadata.price.toString()),
            ",",
            '"license":"',
            bytes(metadata.license),
            '",',
            '"copyNumber":',
            bytes(metadata.copyNumber.toString()),
            ",",
            '"totalCopies":',
            bytes(metadata.totalCopies.toString()),
            "}"
        )
    );
}

}
