// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../libraries/MetadataLib.sol";
contract MetadataManager {
    using MetadataLib for MetadataLib.Metadata;

    /// @notice Logs validation failures for off-chain debugging.
    /// @param field The field that failed validation.
    /// @param reason The reason the field failed validation.
    event MetadataValidationFailed(string field, string reason);

    /// @notice Validates and emits events for metadata errors.
    /// @param metadata The metadata to validate.
    /// @return isValid True if metadata is valid, false otherwise.
    function validateAndLog(MetadataLib.Metadata memory metadata) public returns (bool isValid) {
        (string memory field, string memory reason) = metadata.validateMetadata();
        if (bytes(field).length > 0) {
            emit MetadataValidationFailed(field, reason);
            return false;
        }
        return true;
    }
}
