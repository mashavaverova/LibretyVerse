const { create } = require('ipfs-http-client');
require('dotenv').config();

const ipfs = create({
  url: process.env.IPFS_GATEWAY,
});

module.exports = ipfs;


