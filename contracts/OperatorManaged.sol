pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


// Simple JSE Operator management contract
contract OperatorManaged is Ownable {

    address public operatorAddress;
    address public adminAddress;

    event AdminAddressChanged(address indexed _newAddress);
    event OperatorAddressChanged(address indexed _newAddress);


    function OperatorManaged() public
        Ownable()
    {
		adminAddress=msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    modifier onlyAdminOrOperator() {
        require(isAdmin(msg.sender) || isOperator(msg.sender));
        _;
    }


    modifier onlyOwnerOrAdmin() {
        require(isOwner(msg.sender) || isAdmin(msg.sender));
        _;
    }


    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }


    function isAdmin(address _address) internal view returns (bool) {
        return (adminAddress != address(0) && _address == adminAddress);
    }


    function isOperator(address _address) internal view returns (bool) {
        return (operatorAddress != address(0) && _address == operatorAddress);
    }

    function isOwner(address _address) internal view returns (bool) {
        return (owner != address(0) && _address == owner);
    }


    function isOwnerOrOperator(address _address) internal view returns (bool) {
        return (isOwner(_address) || isOperator(_address));
    }


    // Owner and Admin can change the admin address. Address can also be set to 0 to 'disable' it.
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_adminAddress != owner);
        require(_adminAddress != address(this));
        require(!isOperator(_adminAddress));

        adminAddress = _adminAddress;

        AdminAddressChanged(_adminAddress);

        return true;
    }


    // Owner and Admin can change the operations address. Address can also be set to 0 to 'disable' it.
    function setOperatorAddress(address _operatorAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_operatorAddress != owner);
        require(_operatorAddress != address(this));
        require(!isAdmin(_operatorAddress));

        operatorAddress = _operatorAddress;

        OperatorAddressChanged(_operatorAddress);

        return true;
    }
}