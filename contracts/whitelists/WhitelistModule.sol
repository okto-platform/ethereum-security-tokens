pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract WhitelistModule is Ownable {
    address whitelistAddress;
    string moduleType;

    modifier onlyWhitelist {
        require(whitelistAddress == msg.sender, "Only whitelist can call this method");
        _;
    }

    constructor(address _whitelistAddress, string _moduleType)
    public
    {
        whitelistAddress = _whitelistAddress;
        moduleType = _moduleType;
    }

    function investorUpdated(address investor, bytes32 bucket, bytes32 newValue, bytes32 oldValue) public;
}