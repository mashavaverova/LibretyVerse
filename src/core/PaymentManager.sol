// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PaymentManager is AccessControlEnumerable, ReentrancyGuard {
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256("FUNDS_MANAGER_ROLE");

    address public platformTreasury;

    event FundsReceived(address indexed from, uint256 amount);
    event FundsTransferred(address indexed to, uint256 amount, string reason);
    event TreasuryUpdated(address indexed newTreasury);

    constructor(address _platformAdmin, address _platformTreasury, address initialFundsManager) {
        require(_platformAdmin != address(0), "Invalid admin address");
        require(_platformTreasury != address(0), "Invalid treasury address");
        require(initialFundsManager != address(0), "Invalid funds manager address");

        platformTreasury = _platformTreasury;

        _grantRole(DEFAULT_ADMIN_ROLE, _platformAdmin);
        _grantRole(FUNDS_MANAGER_ROLE, initialFundsManager);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

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

    function updateTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid treasury address");
        platformTreasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

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


    function addFundsManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid account address");
        _grantRole(FUNDS_MANAGER_ROLE, account);
    }

    function removeFundsManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Invalid account address");
        _revokeRole(FUNDS_MANAGER_ROLE, account);
    }

    function isFundsManager(address account) external view returns (bool) {
        return hasRole(FUNDS_MANAGER_ROLE, account);
    }

    function getFundsManagers() external view returns (address[] memory) {
        return getRoleMembers(FUNDS_MANAGER_ROLE); // Use AccessControlEnumerable's built-in method
    }
}
