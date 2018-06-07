pragma solidity ^0.4.18;

import "./JSEToken.sol";
import "zeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20.sol";
import "zeppelin-solidity/contracts/token/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol"; 
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";



/**
 * @title Main JSE Coin Crowdsale Contract (ICO)
 * @author Amr Gawish <amr@gawi.sh>
 * @dev Basic Crowdsale based on Open Zeppelin Crowdsale Contract with some tweaks.
*/
contract JSECoinCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // JSE token being sold
    ERC20 public token;

    // the multi sig wallet address where funds are collected
    address public wallet;

    // address where tokens come from
    address public supplier;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of tokens raised (in wei)
    uint256 public weiTokensRaised = 0;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function JSECoinCrowdsale(address _wallet, address _supplier, address _token, uint256 _rate) public {
        require(_token != address(0));
        require(_supplier != address(0));

        changeWallet(_wallet);
        supplier = _supplier;
        token = ERC20(_token);
        changeRate(_rate);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // change wallet
    function changeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0));

        wallet = _wallet;
    }

    // change rate
    function changeRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        
        rate = _rate;
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable whenNotPaused {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        weiTokensRaised = weiTokensRaised.add(tokens);

        // transfer
        token.safeTransferFrom(supplier, beneficiary, tokens);

        // logs
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        // forward funds to wallet
        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return !paused && nonZeroPurchase;
    }
}