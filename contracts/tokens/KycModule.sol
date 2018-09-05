pragma solidity ^0.4.24;

import "./TokenModule.sol";
import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";

contract KycModule is TokenModule {
    address whitelistAddress;

    constructor(address _whitelistAddress)
    {
        whitelistAddress = _whitelistAddress;
    }

    function isTransferAllowed
    (
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns(uint) {
        Whitelist whitelist = Whitelist(whitelistAddress);
        return whitelist.checkPropertyTrue(_to, "kyc");
    }
}

contract KycModuleFactory is Factory {
    function createInstance(string _whitelistAddress)
    public returns(address)
    {
        KycModule instance = new KycWhitelistModule(_whitelistAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}