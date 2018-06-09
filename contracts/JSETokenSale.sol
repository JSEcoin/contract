pragma solidity ^0.4.23;

import "./JSEToken.sol";
import "./JSECoinCrowdsaleConfig.sol";
import "./OperatorManaged.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


//
// Implementation of the token sale of JSE Token
//
// * Lifecycle *
// Initialization sequence should be as follow:
//    1. Deploy JSEToken contract
//    2. Deploy JSETokenSale contract
//    3. Set operationsAddress of JSEToken contract to JSETokenSale contract
//    4. Transfer tokens from owner to JSETokenSale contract
//    5. Transfer tokens from owner to Distributer Account
//    6. Initialize JSETokenSale contract
//
// Pre-sale sequence:
//    - Set tokensPerKEther
//    - Update whitelist
//    - Start public sale
//
// After-sale sequence:
//    1. Finalize the JSETokenSale contract
//    2. Finalize the JSEToken contract
//    3. Set operationsAddress of JSETokenSale contract to 0
//    4. Set operationsAddress of JSEToken contract to 0


contract JSETokenSale is OperatorManaged, Pausable, JSECoinCrowdsaleConfig { // Pausable is also Owned

    using SafeMath for uint256;


    // We keep track of whether the sale has been finalized, at which point
    // no additional contributions will be permitted.
    bool public finalized;

    // Public Sales start trigger
    bool public publicSaleStarted;

    // Number of tokens per 1000 ETH. See JSETokenSaleConfig for details.
    uint256 public tokensPerKEther;

    // Increase Percentage Bonus of buying tokens
    uint256 public bonusIncreasePercentage = 10; //percentage

    // Address where the funds collected during the sale will be forwarded.
    address public wallet;

    // Token contract that the sale contract will interact with.
    JSEToken public tokenContract;

    // // JSETrustee contract to hold on token balances. The following token pools will be held by trustee:
    // //    - Founders
    // //    - Advisors
    // //    - Early investors
    // //    - Presales
    // address private distributerAccount;

    // Total amount of tokens sold during presale + public sale. Excludes pre-sale bonuses.
    uint256 public totalTokensSold;

    // Total amount of tokens given as bonus during presale. Will influence accelerator token balance.
    uint256 public totalPresaleBase;
    uint256 public totalPresaleBonus;

    // Map of addresses that have been whitelisted in advance (and passed KYC).
    mapping(address => bool) public whitelist;


    //
    // EVENTS
    //
    event Initialized();
    event PresaleAdded(address indexed _account, uint256 _baseTokens, uint256 _bonusTokens);
    event WhitelistUpdated(address indexed _account);
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens, uint256 _totalSold);
    event TokensPerKEtherUpdated(uint256 _amount);
    event WalletChanged(address _newWallet);
    event TokensReclaimed(uint256 _amount);
    event UnsoldTokensBurnt(uint256 _amount);
    event BonusIncreasePercentageChanged(uint256 _oldPercentage, uint256 _newPercentage);
    event Finalized();


    constructor(JSEToken _tokenContract, address _wallet) public
        OperatorManaged()
    {
        require(address(_tokenContract) != address(0));
        //  require(address(_distributerAccount) != address(0));
        require(_wallet != address(0));

        require(TOKENS_PER_KETHER > 0);


        wallet                  = _wallet;
        finalized               = false;
        publicSaleStarted       = false;
        tokensPerKEther         = TOKENS_PER_KETHER;
        tokenContract           = _tokenContract;
        //distributerAccount      = _distributerAccount;
    }


    // Initialize is called to check some configuration parameters.
    // It expects that a certain amount of tokens have already been assigned to the sale contract address.
    function initialize() external onlyOwner returns (bool) {
        require(totalTokensSold == 0);
        require(totalPresaleBase == 0);
        require(totalPresaleBonus == 0);

        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(ownBalance == TOKENS_SALE);

        emit Initialized();

        return true;
    }


    // Allows the admin to change the wallet where ETH contributions are sent.
    function changeWallet(address _wallet) external onlyAdmin returns (bool) {
        require(_wallet != address(0));
        require(_wallet != address(this));
        // require(_wallet != address(distributerAccount));
        require(_wallet != address(tokenContract));

        wallet = _wallet;

        emit WalletChanged(wallet);

        return true;
    }



    //
    // TIME
    //

    function currentTime() public view returns (uint256 _currentTime) {
        return now;
    }


    modifier onlyBeforeSale() {
        require(hasSaleEnded() == false && publicSaleStarted == false);
        _;
    }


    modifier onlyDuringSale() {
        require(hasSaleEnded() == false && publicSaleStarted == true);
        _;
    }

    modifier onlyAfterSale() {
        // require finalized is stronger than hasSaleEnded
        require(finalized);
        _;
    }


    function hasSaleEnded() private view returns (bool) {
        // if sold out or finalized, sale has ended
        if (finalized) {
            return true;
        } else {
            return false;
        }
    }



    //
    // WHITELIST
    //

    // Allows operator to add accounts to the whitelist.
    // Only those accounts will be allowed to contribute above the threshold
    function updateWhitelist(address _account) external onlyAdminOrOperator returns (bool) {
        require(_account != address(0));
        require(!hasSaleEnded());

        whitelist[_account] = true;

        emit WhitelistUpdated(_account);

        return true;
    }

    //
    // PURCHASES / CONTRIBUTIONS
    //

    // Allows the admin to set the price for tokens sold during phases 1 and 2 of the sale.
    function setTokensPerKEther(uint256 _tokensPerKEther) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokensPerKEther > 0);

        tokensPerKEther = _tokensPerKEther;

        emit TokensPerKEtherUpdated(_tokensPerKEther);

        return true;
    }


    function () external payable whenNotPaused onlyDuringSale {
        buyTokens();
    }


    // This is the main function to process incoming ETH contributions.
    function buyTokens() public payable whenNotPaused onlyDuringSale returns (bool) {
        require(msg.value >= CONTRIBUTION_MIN);
        require(msg.value <= CONTRIBUTION_MAX);
        require(totalTokensSold < TOKENS_SALE);

        // All accounts need to be whitelisted to purchase.
        bool whitelisted = whitelist[msg.sender];
        if(msg.value >= CONTRIBUTION_MAX_NO_WHITELIST){
            require(whitelisted);
        }

        uint256 tokensMax = TOKENS_SALE.sub(totalTokensSold);

        require(tokensMax > 0);

        uint256 tokensBought = msg.value.mul(tokensPerKEther).mul(bonusIncreasePercentage).div(PURCHASE_DIVIDER).div(100);
        require(tokensBought > 0);

        uint256 cost = msg.value;
        uint256 refund = 0;

        if (tokensBought > tokensMax) {
            // Not enough tokens available for full contribution, we will do partial.
            tokensBought = tokensMax;

            // Calculate actual cost for partial amount of tokens.
            cost = tokensBought.mul(PURCHASE_DIVIDER).div(tokensPerKEther);

            // Calculate refund for contributor.
            refund = msg.value.sub(cost);
        }

        totalTokensSold = totalTokensSold.add(tokensBought);

        // Transfer tokens to the account
        require(tokenContract.transfer(msg.sender, tokensBought));

        // Issue a ETH refund for any unused portion of the funds.
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

        // Transfer the contribution to the wallet
        wallet.transfer(msg.value.sub(refund));

        emit TokensPurchased(msg.sender, cost, tokensBought, totalTokensSold);

        // If all tokens available for sale have been sold out, finalize the sale automatically.
        if (totalTokensSold == TOKENS_SALE) {
            finalizeInternal();
        }

        return true;
    }



    // Allows the admin to move bonus tokens still available in the sale contract
    // out before burning all remaining unsold tokens in burnUnsoldTokens().
    // Used to distribute bonuses to token sale participants when the sale has ended
    // and all bonuses are known.
    function reclaimTokens(uint256 _amount) external onlyAfterSale onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(_amount <= ownBalance);
        
        address tokenOwner = tokenContract.owner();
        require(tokenOwner != address(0));

        require(tokenContract.transfer(tokenOwner, _amount));

        emit TokensReclaimed(_amount);

        return true;
    }

    function changeBonusIncreasePercentage(uint256 _newPercentage) external onlyDuringSale onlyAdmin returns (bool) {
        uint oldPercentage = bonusIncreasePercentage;
        bonusIncreasePercentage = _newPercentage;
        emit BonusIncreasePercentageChanged(oldPercentage, _newPercentage);
        return true;
    }

    // Allows the admin to finalize the sale and complete allocations.
    // The JSEToken.admin also needs to finalize the token contract
    // so that token transfers are enabled.
    function finalize() external onlyAdmin returns (bool) {
        return finalizeInternal();
    }

    function startPublicSale() external onlyAdmin onlyBeforeSale returns (bool) {
        publicSaleStarted = true;
        return true;
    }


    // The internal one will be called if tokens are sold out or
    // the end time for the sale is reached, in addition to being called
    // from the public version of finalize().
    function finalizeInternal() private returns (bool) {
        require(!finalized);

        finalized = true;

        emit Finalized();

        return true;
    }
}
