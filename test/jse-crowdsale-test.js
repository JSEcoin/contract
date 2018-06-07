const JSECoinCrowdsale = artifacts.require("./JSECoinCrowdsale.sol");
const JSEToken = artifacts.require("./JSEToken.sol");
const MultiSigWallet = artifacts.require("./wallet/MultiSigWallet.sol");

contract('JSECoinCrowdsale', function (accounts) {
  let instance = JSECoinCrowdsale.at(JSECoinCrowdsale.address);
  let supplier = accounts[0];
  let wallet = MultiSigWallet.address;

  let otherAccount = accounts[1];

  it("Ensuring Wallet address and Token address are correct", async () => {
    let tokenAddress = await instance.token();
    let walletAddress = await instance.wallet();

    assert(tokenAddress === JSEToken.address, 'Instance token address should be the same as JSEtoken address');
    assert(walletAddress === MultiSigWallet.address, 'Wallet address should be the same as MultiSigWallet address');
  });
});