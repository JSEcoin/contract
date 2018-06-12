const BigNumber = require('bignumber.js')

var JSEToken = artifacts.require("./JSEToken.sol")
var TokenSale = artifacts.require("./JSETokenSale.sol")


module.exports = function (deployer, network, accounts) {

    let token = null
    let sale = null
    let walletAddress = null;
    
    if(network === 'development'){
        walletAddress = accounts[1];
    }else{
        walletAddress = process.env.WALLET_ADDRESS;
    }

    var TOKENS_SALE = 0

    return deployer.deploy(JSEToken).then(() => {
        return JSEToken.deployed().then(instance => { 
            token = instance 
        })
    }).then(() => {
        return deployer.deploy(TokenSale, token.address, walletAddress)
    }).then(() => {
        return TokenSale.deployed().then(instance => { 
            sale = instance 
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