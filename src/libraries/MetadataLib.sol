// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/console.sol";
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

    error EmptyField(string field);
    error InvalidURI(string uri);
    error InvalidPrice();
    error InvalidCopyNumber(uint256 copyNumber, uint256 totalCopies);

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

    function formatMetadata(Metadata memory metadata) internal pure returns (string memory formattedMetadata) {
        formattedMetadata = string(
            abi.encodePacked(
                "{",
                '"title":"',
                metadata.title,
                '",',
                '"author":"',
                metadata.author,
                '",',
                '"contentLink":"',
                metadata.contentLink,
                '",',
                '"price":',
                metadata.price.toString(),
                ",",
                '"license":"',
                metadata.license,
                '",',
                '"copyNumber":',
                metadata.copyNumber.toString(),
                ",",
                '"totalCopies":',
                metadata.totalCopies.toString(),
                "}"
            )
        );
    }
}
