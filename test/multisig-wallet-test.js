const JSECoinCrowdsale = artifacts.require("./JSECoinCrowdsale.sol");
const JSEToken = artifacts.require("./JSEToken.sol");
const MultiSigWallet = artifacts.require("./wallet/MultiSigWallet.sol");

contract('MultiSigWallet', function (accounts) {
  let instance = MultiSigWallet.at(MultiSigWallet.address);
  let owner1 = accounts[0];
  let owner2 = accounts[1];

  let otherAccount = accounts[2];

  it('Making sure that first 2 accounts are owners', async () => {
      let isWalletOwner1 = await instance.isOwner(owner1);
      let isWalletOwner2 = await instance.isOwner(owner2);
      let isWalletOwner3 = await instance.isOwner(otherAccount); 

      assert(isWalletOwner1, 'Owner 1 should be an owner of the wallet');
      assert(isWalletOwner2, 'Owner 2 should be an owner of the wallet');
      assert(!isWalletOwner3, 'Other account should not be an owner of the wallet');
  });
});