pragma solidity ^0.4.24;

import "./TokenModule.sol";
import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";

contract KycModule is TokenModule {
    address whitelistAddress;

    constructor(address _tokenAddress, address _whitelistAddress)
    TokenModule(_tokenAddress)
    public
    {
        whitelistAddress = _whitelistAddress;
    }

    function isTransferAllowed(address, address _to, uint256)
    public
    returns(TransferAllowanceResult) {
        Whitelist whitelist = Whitelist(whitelistAddress);
        if (whitelist.checkPropertyTrue(_to, "kyc")) {
            return TransferAllowanceResult.Allowed;
        } else {
            return TransferAllowanceResult.NotAllowed;
        }
    }
}

contract KycModuleFactory is Factory {
    function createInstance(address _tokenAddress, address _whitelistAddress)
    public returns(address)
    {
        KycModule instance = new KycModule(_tokenAddress, _whitelistAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}