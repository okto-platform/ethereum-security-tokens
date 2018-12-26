pragma solidity ^0.5.0;

import "../utils/Ownable.sol";
import "../modules/Module.sol";

contract WhitelistModule is Module {
    address public whitelistAddress;
    string public moduleType;

    modifier onlyWhitelist {
        require(whitelistAddress == msg.sender, "Only whitelist can call this method");
        _;
    }

    constructor(address _whitelistAddress, string memory _moduleType)
    public
    {
        whitelistAddress = _whitelistAddress;
        moduleType = _moduleType;
    }

    function investorUpdated(address investor, bytes32 bucket, bytes32 newValue, bytes32 oldValue) public;
}
