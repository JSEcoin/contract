pragma solidity ^0.4.23;

/**
 * @title Interface for an ERC223 Contract
 * @author Amr Gawish <amr@gawi.sh>
 * @dev Only one method is unique to contracts `transfer(address _to, uint _value, bytes _data)`
 * @notice The interface has been stripped to its unique methods to prevent duplicating methods with ERC20 interface
*/
interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}