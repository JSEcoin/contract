const BigNumber = web3.BigNumber;

module.exports = function calculateTokens (etherValue) {
    const tokensPerKEther = new BigNumber(105000000);
    const PURCHASE_DIVIDER = new BigNumber(1000);
    const tokensBonus = new BigNumber(10);
    const BONUS_DIVIDER = new BigNumber(100);
    const beforeBonus = etherValue.mul(tokensPerKEther).div(PURCHASE_DIVIDER);
    const bonus = beforeBonus.mul(tokensBonus).div(BONUS_DIVIDER);
    return beforeBonus.add(bonus);
  }