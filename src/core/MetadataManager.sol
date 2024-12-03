// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../libraries/MetadataLib.sol";

/// @title MetadataManager
/// @notice Handles metadata validation and emits events for off-chain debugging.
contract MetadataManager {
    using MetadataLib for MetadataLib.Metadata;

    /// @notice Logs validation failures for off-chain debugging.
    /// @param field The field that failed validation.
    /// @param reason The reason the field failed validation.
    event MetadataValidationFailed(string field, string reason);

    /// @notice Logs successful metadata validation.
    event MetadataValidated(
        string title,
        string author,
        string contentLink,
        uint256 price,
        string license,
        uint256 copyNumber,
        uint256 totalCopies
    );

    /// @notice Validates and emits events for metadata validation status.
    /// @param metadata The metadata to validate.
    /// @return isValid True if metadata is valid, false otherwise.
    function validateAndLog(MetadataLib.Metadata memory metadata) public returns (bool isValid) {
        (string memory field, string memory reason) = metadata.validateMetadata();
        if (bytes(field).length > 0) {
            emit MetadataValidationFailed(field, reason);
            return false;
        }

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
