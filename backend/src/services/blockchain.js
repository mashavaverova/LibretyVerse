const Web3 = require('web3');
require('dotenv').config();

const web3 = new Web3(new Web3.providers.HttpProvider(`https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`));

module.exports = web3;
