import Web3 from 'web3';
import fs from 'fs';
import path from 'path';
import ENV from './src/config/environment.mjs';

// Load the PaymentManager ABI
const ABI_PATH = path.resolve('src/contracts/PaymentManager.json');
const paymentManagerABI = JSON.parse(fs.readFileSync(ABI_PATH, 'utf-8'));

// Initialize Web3
const web3 = new Web3(ENV.anvilRpcUrl);

// Initialize the PaymentManager contract
const paymentManagerContract = new web3.eth.Contract(paymentManagerABI.abi, ENV.contractAddresses.paymentManager);

// Export Web3 and contract instance
export { web3, paymentManagerContract };

// Add the admin account to the wallet
const account = web3.eth.accounts.privateKeyToAccount(ENV.privateKeyAnvil0);
web3.eth.accounts.wallet.add(account);
console.log("Wallet accounts:", web3.eth.accounts.wallet);

(async () => {
    try {
        // Fetch the role hash for FUNDS_MANAGER_ROLE
        const roleHash = await paymentManagerContract.methods.FUNDS_MANAGER_ROLE().call();
        console.log("FUNDS_MANAGER_ROLE hash:", roleHash);

        // Encode the transaction data for granting the role
        const data2 = paymentManagerContract.methods.grantRole(roleHash, account.address).encodeABI();
        console.log("DATA2:", data2);
    } catch (error) {
        console.error("Error:", error.message);
    }
})();
