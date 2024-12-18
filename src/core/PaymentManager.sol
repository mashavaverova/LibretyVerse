// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PaymentManager is AccessControl, ReentrancyGuard {
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");

    address public platformTreasury; // Address of the platform treasury

    event FundsReceived(address indexed from, uint256 amount);
    event FundsTransferred(address indexed to, uint256 amount, string reason);
    event TreasuryUpdated(address indexed newTreasury);

    constructor(address _platformAdmin, address _platformTreasury) {
        require(_platformAdmin != address(0), "Invalid platform admin address");
        require(_platformTreasury != address(0), "Invalid treasury address");

        platformTreasury = _platformTreasury;

        // Assign default roles
        _grantRole(DEFAULT_ADMIN_ROLE, _platformAdmin);
        _grantRole(FUNDS_MANAGER_ROLE, _platformAdmin);
    }

    // Allow the contract to receive ETH
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Transfer funds to a specific address for a specified reason.
     * Only callable by accounts with the FUNDS_MANAGER_ROLE.
     * @param to Recipient of the funds.
     * @param amount Amount to transfer (in wei).
     * @param reason Reason for the transfer (e.g., "Salary Payment", "Royalty Payout").
     */
    function transferFunds(address payable to, uint256 amount, string calldata reason)
        external
        onlyRole(FUNDS_MANAGER_ROLE)
        nonReentrant
    {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient contract balance");

        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsTransferred(to, amount, reason);
    }

    /**
     * @dev Update the platform treasury address.
     * Only callable by accounts with the DEFAULT_ADMIN_ROLE.
     * @param newTreasury New treasury address.
     */
    function updateTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid treasury address");
        platformTreasury = newTreasury;

        emit TreasuryUpdated(newTreasury);
    }

    /**
     * @dev Withdraw all contract funds to the platform treasury.
     * Only callable by accounts with the FUNDS_MANAGER_ROLE.
     */
    function withdrawToTreasury() external onlyRole(FUNDS_MANAGER_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success,) = payable(platformTreasury).call{value: balance}("");
        require(success, "Withdrawal to treasury failed");

        emit FundsTransferred(platformTreasury, balance, "Withdrawal to Treasury");
    }

    /**
     * @dev View the current balance of the contract.
     * @return uint256 Contract balance (in wei).
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
