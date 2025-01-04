// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../libraries/MetadataLib.sol";
/**
 * @title MetadataManager
 * @dev Manages and validates metadata using the MetadataLib library.
 * @notice created by @mashavaverova
 */

contract MetadataManager {
    using MetadataLib for MetadataLib.Metadata;

     /**
     * @notice Emitted when metadata validation fails.
     * @param field The name of the field that failed validation.
     * @param reason The reason for the validation failure.
     */
    event MetadataValidationFailed(string field, string reason);

    /**
     * @notice Emitted when metadata is successfully validated.
     * @param title The title of the content.
     * @param author The author of the content.
     * @param contentLink A link to the content.
     * @param price The price of the content in ETH.
     * @param license The license type of the content.
     * @param copyNumber The current copy number of the content.
     * @param totalCopies The total number of copies available.
     */
    event MetadataValidated(
        string title,
        string author,
        string contentLink,
        uint256 price,
        string license,
        uint256 copyNumber,
        uint256 totalCopies
    );

/* =======================================================
                     External Functions
   ======================================================= */
    /**
     * @notice Validates metadata and emits an event if the metadata is valid.
     * @param metadata The metadata to validate.
     * @return Returns true if the metadata is successfully validated.
     * @dev Uses the MetadataLib library for validation.
     */
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
