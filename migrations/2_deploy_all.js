const BigNumber = require('bignumber.js')

var JSEToken = artifacts.require("./JSEToken.sol")
var TokenSale = artifacts.require("./JSETokenSale.sol")


module.exports = function (deployer, network, accounts) {

    var token = null
    var sale = null
    var walletAddress = process.env.WALLET_ADDRESS

    var TOKENS_SALE = 0

    return deployer.deploy(JSEToken).then(() => {
        return JSEToken.deployed().then(instance => { 
            token = instance 
            console.log("Token Address is: "+token);
        })
    }).then(() => {
        return deployer.deploy(TokenSale, token.address, walletAddress)
    }).then(() => {
        return TokenSale.deployed().then(instance => { 
            sale = instance 
            console.log("Sale Address is: "+sale);
        })
    }).then(() => {
        return token.setOperatorAddress(sale.address)
    }).then(() => {
        return sale.TOKENS_SALE.call().then(tokensSale => { TOKENS_SALE = tokensSale })
    }).then(() => {
        return token.transfer(sale.address, TOKENS_SALE)
    }).then(() => {
        return sale.initialize()
    })
}