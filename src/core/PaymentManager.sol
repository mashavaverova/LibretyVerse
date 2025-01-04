// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PaymentManager
 * @dev Manages the receipt and transfer of funds, with role-based access control for fund managers.
 * @notice created by @mashavaverova
 */
contract PaymentManager is AccessControlEnumerable, ReentrancyGuard {
    /**
     * @notice Role identifier for fund managers who can transfer and manage funds.
     */
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");

    /**
     * @notice Address of the platform treasury to which funds can be withdrawn.
     */
    address public platformTreasury;

    /** @notice Events */
    event FundsReceived(address indexed from, uint256 amount);
    event FundsTransferred(address indexed to, uint256 amount, string reason);
    event TreasuryUpdated(address indexed newTreasury);

    /**
     * @notice Constructor to initialize the PaymentManager contract.
     * @param _platformAdmin Address of the platform admin with the default admin role.
     * @param _platformTreasury Address of the platform treasury to receive funds.
     * @param initialFundsManager Address of the initial funds manager.
     */
    constructor(address _platformAdmin, address _platformTreasury, address initialFundsManager) {
        require(_platformAdmin != address(0), "Invalid admin address");
        require(_platformTreasury != address(0), "Invalid treasury address");
        require(initialFundsManager != address(0), "Invalid funds manager address");

        platformTreasury = _platformTreasury;

        _grantRole(DEFAULT_ADMIN_ROLE, _platformAdmin);
        _grantRole(FUNDS_MANAGER_ROLE, initialFundsManager);
    }

/* =======================================================
                     Fallback Functions
   ======================================================= */

    /**
     * @notice Fallback function to handle plain ETH transfers.
     * @dev Emits a `FundsReceived` event.
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
    /**
     * @notice Fallback function to handle plain ETH transfers with calldata.
     * @dev Emits a `FundsReceived` event.
     */
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
/* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Transfers funds to a specified recipient.
     * @param to Address of the recipient.
     * @param amount Amount of ETH to transfer.
     * @param reason Reason for the transfer.
     * @dev Only callable by users with the `FUNDS_MANAGER_ROLE`. Ensures sufficient contract balance.
     */
    function transferFunds(address payable to, uint256 amount, string calldata reason)
        external
        nonReentrant
        onlyRole(FUNDS_MANAGER_ROLE)
        
    {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsTransferred(to, amount, reason);
    }

    /**
     * @notice Updates the platform treasury address.
     * @param newTreasury Address of the new treasury.
     * @dev Only callable by the default admin role.
     */
    function updateTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid treasury address");
        platformTreasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    /**
     * @notice Withdraws all contract funds to the platform treasury.
     * @dev Ensures the treasury address is valid. Only callable by fund managers.
     */
    function withdrawToTreasury() external nonReentrant onlyRole(FUNDS_MANAGER_ROLE) {
        uint256 balance = address(this).balance;

        // Check contract balance
        require(balance > 0, "No funds to withdraw");

        // Validate the platform treasury address
        require(platformTreasury != address(0), "Invalid treasury address");
        require(platformTreasury != address(this), "Cannot withdraw to contract itself");

        // Perform the transfer
        (bool success,) = payable(platformTreasury).call{value: balance}("");
        require(success, "Withdrawal failed");

        // Emit the withdrawal event
        emit FundsTransferred(platformTreasury, balance, "Withdrawal to Treasury");
    }

    /**
     * @notice Grants the funds manager role to a specific address.
     * @param account Address to grant the funds manager role.
     * @dev Only callable by the default admin role.
     */
    function addFundsManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid account address");
        _grantRole(FUNDS_MANAGER_ROLE, account);
    }

    /**
     * @notice Revokes the funds manager role from a specific address.
     * @param account Address to revoke the funds manager role.
     * @dev Only callable by the default admin role.
     */
    function removeFundsManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid account address");
        _revokeRole(FUNDS_MANAGER_ROLE, account);
    }

 /* =======================================================
                      View Functions
   ======================================================= */
    /**
     * @notice Checks if an address has the funds manager role.
     * @param account Address to check.
     * @return True if the address has the funds manager role, otherwise false.
     */
    function isFundsManager(address account) external view returns (bool) {
        return hasRole(FUNDS_MANAGER_ROLE, account);
    }

    /**
     * @notice Retrieves a list of all funds managers.
     * @return An array of addresses with the funds manager role.
     */
    function getFundsManagers() external view returns (address[] memory) {
        return getRoleMembers(FUNDS_MANAGER_ROLE); // Use AccessControlEnumerable's built-in method
    }
}
