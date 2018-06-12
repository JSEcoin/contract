// Nodifying the code from https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/test/helpers/ether.js
module.exports = function ether (n) {
    return new web3.BigNumber(web3.toWei(n, 'ether'));
  }