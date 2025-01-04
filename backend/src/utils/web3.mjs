import Web3 from 'web3';
import { ENV } from '../config/environment.mjs';

// Ensure environment variables are defined
if (!ENV.anvilRpcUrl) {
    throw new Error('ANVIL_RPC_URL is not defined in the environment variables.');
}
if (!ENV.privateKeyAnvil0) {
    throw new Error('PRIVATE_KEY_ANVIL_0 is not defined in the environment variables.');
}

// Initialize Web3 with the RPC URL
const web3 = new Web3(new Web3.providers.HttpProvider(ENV.anvilRpcUrl));
console.log('Connected to RPC:', ENV.anvilRpcUrl);

// Add the private key to the wallet
const account = web3.eth.accounts.privateKeyToAccount(ENV.privateKeyAnvil0);
web3.eth.accounts.wallet.add(account);
console.log('Loaded Account:', account.address);
console.log('Wallet accounts:', web3.eth.accounts.wallet);
console.log ('web3.mjs loaded');

export default web3;
