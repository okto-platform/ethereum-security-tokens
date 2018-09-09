pragma solidity ^0.4.24;

import "./TokenOfferingModule.sol";
import "./TokenOffering.sol";
import "../utils/Factory.sol";
import "../whitelists/Whitelist.sol";

contract KycModule is TokenOfferingModule {
    address whitelistAddress;

    constructor(address _tokenOfferingAddress, address _whitelistAddress)
    TokenOfferingModule(_tokenOfferingAddress)
    public
    {
        whitelistAddress = _whitelistAddress;
    }

    function allowAllocation(address _to, uint256)
    public returns(AllocationAllowanceResult)
    {
        Whitelist whitelist = Whitelist(whitelistAddress);
        if (whitelist.checkPropertyTrue(_to, "kyc")) {
            return AllocationAllowanceResult.Allowed;
        } else {
            emit AllocationRejected("kyc", "Investor has not passed KYC validation");
            return AllocationAllowanceResult.NotAllowed;
        }
    }
}

contract KycModuleFactory is Factory {
    function createInstance(address _tokensAddress, address _whitelistAddress)
    public returns(address)
    {
        KycModule instance = new KycModule(_tokensAddress, _whitelistAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}