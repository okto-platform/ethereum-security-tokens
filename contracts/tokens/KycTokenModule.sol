pragma solidity ^0.4.24;

import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";
import "./TokenModule.sol";

contract KycTokenModule is TransferValidatorTokenModule,TokenModule {
    address public whitelistAddress;

    bytes32 constant KYC_PROP = bytes32("kyc");

    constructor(address _tokenAddress, address _whitelistAddress)
    TokenModule(_tokenAddress, "kyc")
    public
    {
        whitelistAddress = _whitelistAddress;
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](1);
        features[0] = TokenModule.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address, address to, uint256, bytes, bytes)
    public view returns (byte, string)
    {
        Whitelist whitelist = Whitelist(whitelistAddress);
        if (whitelist.getProp(to, KYC_PROP) == 1) {
            return (0xA1, "Approved");
        } else {
            return (0xA6, "Receiver not in whitelist");
        }
    }
}

contract KycTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, address _whitelistAddress)
    public returns(address)
    {
        KycTokenModule instance = new KycTokenModule(_tokenAddress, _whitelistAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}