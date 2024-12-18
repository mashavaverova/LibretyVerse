// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../libraries/MetadataLib.sol";

contract MetadataManager {
    using MetadataLib for MetadataLib.Metadata;

    event MetadataValidationFailed(string field, string reason);
    event MetadataValidated(
        string title,
        string author,
        string contentLink,
        uint256 price,
        string license,
        uint256 copyNumber,
        uint256 totalCopies
    );

    function validateAndLog(MetadataLib.Metadata memory metadata) public returns (bool) {
        metadata.validateMetadata();

        emit MetadataValidated(
            metadata.title,
            metadata.author,
            metadata.contentLink,
            metadata.price,
            metadata.license,
            metadata.copyNumber,
            metadata.totalCopies
        );

        return true;
    }
}
