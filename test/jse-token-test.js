const JSEToken = artifacts.require("./JSEToken.sol");


contract('JSEToken', function (accounts) {
  let instance = JSEToken.at(JSEToken.address);
  let owner = accounts[0];

  let otherAccount = accounts[1];

  it("Making sure that the initial balance and total balance equals to 1,000,000,000 x 10 ^ 18", async () => {
    let initialSupply = await instance.initialSupply();
    let totalSupply = await instance.totalSupply();

    assert(initialSupply.toNumber() === (1000000000 * Math.pow(10, 18)));
    assert(totalSupply.toNumber() === (1000000000 * Math.pow(10, 18)));
  });


  it("Making sure that the decimal is 18", async () => {
    let decimal = await instance.decimals();

    assert(decimal.toNumber() === 18);
  });

  it("Checking the balance of Owner = totalSupply", async () => {
    let ownerBalance = await instance.balanceOf(owner);
    let totalSupply = await instance.totalSupply();

    assert(ownerBalance.toNumber() === totalSupply.toNumber());
  });

  
  it("Checking account balances after transfering Tokens from Owner to otherAccount", async () => {
    let totalSupply = await instance.totalSupply();
    let transferEvent = instance.Transfer();
    let valueToTransfer = 1000;
    let originalOwnerBalance = await instance.balanceOf(owner);
    let originalOtherAccountBalance = await instance.balanceOf(otherAccount);

    assert(originalOwnerBalance.toNumber() === totalSupply.toNumber());
    assert(originalOtherAccountBalance.toNumber() === 0);

    instance.transfer(otherAccount, valueToTransfer);

    transferEvent.watch(async (err, response) => {
      if (!err) {
        let currentOwnerBalance = await instance.balanceOf(owner);
        let currentOtherAccountBalance = await instance.balanceOf(otherAccount);
        
        assert(currentOwnerBalance.toNumber() === originalOwnerBalance.toNumber() - valueToTransfer, 'The owner balance should be less than before the transfer');
        assert(currentOtherAccountBalance.toNumber() == originalOtherAccountBalance.toNumber() + valueToTransfer, 'The other account balance should be more than before the transfer');
      }
    });

  });

  it("Check that the minted address gets new tokens and the total supply increases", async () => {

    let totalSupply = await instance.totalSupply();
    let mintEvent = instance.Mint();
    let valueToMint = 1000;
    let originalOwnerBalance = await instance.balanceOf(owner);

    instance.mint(owner, valueToMint);

    mintEvent.watch(async (err, response) => {
      if (!err) {
        let currentOwnerBalance = await instance.balanceOf(owner);
        let currentTotalSupply = await instance.totalSupply();
        assert(currentOwnerBalance.toNumber() === originalOwnerBalance.toNumber() + valueToMint, 'The owner balance should be more than before the minting');
        assert(currentTotalSupply.toNumber() === totalSupply.toNumber() + valueToMint, 'The Total Supply should be more than before the mint');
      }
    });
  });

  it("Validate that minting cannot happen when Minting is finished", async () => {

    let totalSupply = await instance.totalSupply();
    let mintEvent = instance.MintFinished();
    let valueToMint = 1000;
    let originalOwnerBalance = await instance.balanceOf(owner);

    instance.finishMinting();

    mintEvent.watch(async (err, response) => {
      if (!err) {
        try {
          let tx = await instance.mint(owner, valueToMint);
          assert(false, 'Owner should not be able to Mint anymore');
        } catch (ex) {
          assert(true, 'Revert Transaction occured and no minting occured');
          let currentOwnerBalance = await instance.balanceOf(owner);
          let currentTotalSupply = await instance.totalSupply();
          assert(currentOwnerBalance.toNumber() === originalOwnerBalance.toNumber(), 'The owner balance should be the same');
          assert(currentTotalSupply.toNumber() === totalSupply.toNumber(), 'The Total Supply should be the same');

        }
      }
    });


  });

  it("Validate Burning Mechanism is working as intended", async () => {
    let totalSupply = await instance.totalSupply();
    let burnEvent = instance.Burn();
    let valueToBurn = 1000;
    let originalOwnerBalance = await instance.balanceOf(owner);

    instance.burn(valueToBurn);

    burnEvent.watch(async (err, response) => {
      if (!err) {
        let currentOwnerBalance = await instance.balanceOf(owner);
        let currentTotalSupply = await instance.totalSupply();
        assert(currentOwnerBalance.toNumber() === originalOwnerBalance.toNumber() - valueToBurn, 'The owner balance should be the less by the amount of burned tokens');
        assert(currentTotalSupply.toNumber() === totalSupply.toNumber() - valueToBurn, 'The Total Supply should be the less by the amount of burned tokens');
      }
    });
  });


  /*
  it("//TODO Assert ERC223 compliance", async () => {
    assert(false, 'Not yet implemented');
  });
  */

});
