pragma solidity ^0.4.24;

import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";
import "./TokenModule.sol";

contract RestrictSenderTokenModule is TransferValidatorTokenModule,TokenModule {
    address public whitelistAddress;
    bool public allowOperators;
    bool public allowAts;

    bytes32 constant ATS_PROP = bytes32("ats");

    constructor(address _tokenAddress, address _whitelistAddress, bool _allowOperators, bool _allowAts)
    TokenModule(_tokenAddress, "restrictSender")
    public
    {
        require(_allowOperators || _allowAts, "You need to allow at least one type of users");

        whitelistAddress = _whitelistAddress;
        allowOperators = _allowOperators;
        allowAts = _allowAts;
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](1);
        features[0] = TokenModule.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address operator, address from, address, uint256, bytes)
    public view returns (byte, string)
    {
        Whitelist whitelist = Whitelist(whitelistAddress);
        if (
            allowOperators && operator != address(0) ||
            allowAts && operator == address(0) && whitelist.getProperty(from, ATS_PROP) == 1
        ) {
            return (0xA1, "Approved");
        } else {
            return (0xA5, "Sender is restricted");
        }
    }
}

contract RestrictSenderTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, address _whitelistAddress, bool _allowOperators, bool _allowAts)
    public returns(address)
    {
        RestrictSenderTokenModule instance = new RestrictSenderTokenModule(_tokenAddress, _whitelistAddress, _allowOperators, _allowAts);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}