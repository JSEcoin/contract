const ether = require('./helpers/ether');
const tokensCalculator = require('./helpers/tokensCalculator');

const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const JSETokenSale = artifacts.require('JSETokenSale');
const JSEToken = artifacts.require('JSEToken');

contract('JSETokenSale', function ([_, investor, wallet, purchaser]) {
  const value = ether(5);
  let tokenSupply = null;
  const expectedTokenAmount = tokensCalculator(value);

  beforeEach(async function () {
    this.token = await JSEToken.new();
    this.sale = await JSETokenSale.new(this.token.address, wallet);
    tokenSupply = await this.sale.TOKENS_SALE.call();

    await this.token.setOperatorAddress(this.sale.address);
    await this.token.transfer(this.sale.address, tokenSupply);
    await this.sale.initialize();
    await this.sale.startPublicSale();
  });

  describe('accepting payments', function () {
    it('should accept payments', async function () {
      await this.sale.send(value).should.be.fulfilled;
      await this.sale.buyTokens({ value: value, from: purchaser }).should.be.fulfilled;
    });
  });

  describe('high-level purchase', function () {
    it('should log purchase', async function () {
      const { logs } = await this.sale.sendTransaction({ value: value, from: investor });
      const event = logs.find(e => e.event === 'TokensPurchased');
      should.exist(event);
      event.args._beneficiary.should.equal(investor);
      event.args._cost.should.be.bignumber.equal(value);
      event.args._tokens.should.be.bignumber.equal(expectedTokenAmount);
    });

    it('should forward funds to wallet', async function () {
      const pre = web3.eth.getBalance(wallet);
      await this.sale.sendTransaction({ value, from: investor });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  });

});
