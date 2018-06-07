pragma solidity ^0.4.18;

import "./ERC223.sol";
import "./ERC223ReceivingContract.sol";
import "./OperatorManaged.sol";
import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/MintableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20.sol";

/**
 * @title Main Token Contract for JSE Coin
 * @author Amr Gawish <amr@gawi.sh>
 * @dev This Token is the Mintable and Burnable to allow variety of actions to be done by users.
 * @dev It also complies with both ERC20 and ERC223.
 * @notice Trying to use JSE Token to Contracts that doesn't accept tokens and doesn't have tokenFallback function will fail, and all contracts
 * must comply to ERC223 compliance. 
*/
contract JSEToken is ERC223, BurnableToken, Ownable, MintableToken, OperatorManaged {
    
    event Finalized();

    string public name = "JSE Token";
    string public symbol = "JSE";
    uint public decimals = 18;
    uint public initialSupply = 10000000000 * (10 ** decimals); //10,000,000,000 aka 10 billion

    bool public finalized;

    function JSEToken() OperatorManaged() public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply; 

        Transfer(0x0, msg.sender, initialSupply);
    }


    // Implementation of the standard transferFrom method that takes into account the finalize flag.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }

    function checkTransferAllowed(address _sender, address _to) private view {
        if (finalized) {
            // Everybody should be ok to transfer once the token is finalized.
            return;
        }

        // Owner and Ops are allowed to transfer tokens before the sale is finalized.
        // This allows the tokens to move from the TokenSale contract to a beneficiary.
        // We also allow someone to send tokens back to the owner. This is useful among other
        // cases, for the Trustee to transfer unlocked tokens back to the owner (reclaimTokens).
        require(isOwnerOrOperator(_sender) || _to == owner);
    }

    // Implementation of the standard transfer method that takes into account the finalize flag.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transfer(_to, _value);
    }

    /**
    * @dev transfer token for a specified contract address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Additional Data sent to the contract.
    */
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        checkTransferAllowed(msg.sender, _to);

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(isContract(_to));


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract erc223Contract = ERC223ReceivingContract(_to);
        erc223Contract.tokenFallback(msg.sender, _value, _data);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /** 
    * @dev Owner can transfer out any accidentally sent ERC20 tokens
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    function isContract(address _addr) private view returns (bool) {
        uint codeSize;
        /* solium-disable-next-line */
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    // Finalize method marks the point where token transfers are finally allowed for everybody.
    function finalize() external onlyAdmin returns (bool success) {
        require(!finalized);

        finalized = true;

        Finalized();

        return true;
    }
}