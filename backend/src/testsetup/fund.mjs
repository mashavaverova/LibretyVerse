import web3 from './web3.mjs';

async function fundAccount() {
    const fromAccount = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'; // Replace with a funded account
    const toAccount = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'; // Replace with the low-balance account

    try {
        const tx = await web3.eth.sendTransaction({
            from: fromAccount,
            to: toAccount,
            value: web3.utils.toWei('10', 'ether'), // Send 10 ETH
            gas: 21000,
        });

        console.log('Transaction hash:', tx.transactionHash);

        const balance = await web3.eth.getBalance(toAccount);
        console.log(`New Balance of ${toAccount}: ${web3.utils.fromWei(balance, 'ether')} ETH`);
    } catch (error) {
        console.error('Error funding account:', error);
    }
}

fundAccount();
