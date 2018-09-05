pragma solidity ^0.4.24;

import "./TokenOfferingModule.sol";
import "./TokenOffering.sol";
import "../utils/Factory.sol";

contract TokensHardCapModule is TokenOfferingModule {
    uint256 hardCap;

    constructor(address _tokenOfferingAddress, uint256 _hardCap) {
        super(_tokenOfferingAddress);
        hardCap = _hardCap;
    }

    function allowAllocation(address _to, uint256 _amount)
    public returns(bool)
    {
        TokenOffering offering = TokenOffering(tokenOfferingAddress);
        var currentAmountOfTokens = offering.getTotalAllocatedTokens();
        bool allowed = (currentAmountOfTokens + _amount) <= hardCap;
        if (!allowed) {
            emit AllocationRejected("hardCap", "Hard cap reached");
        }
        return allowed;
    }
}

contract TokensHardCapModuleFactory is Factory {
    function createInstance(string _tokensOfferingAddress, uint256 _hardCap)
    public returns(address)
    {
        TokensHardCapModule instance = new TokensHardCapModule(_tokensOfferingAddress, _hardCap);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}