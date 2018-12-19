pragma solidity ^0.4.24;

import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";
import "./TokenModule.sol";

contract RestrictSenderTokenModule is TransferValidatorTokenModule,TokenModule {
    address public whitelistAddress;
    bool public allowOperators;
    bool public allowExchangers;

    bytes32 constant EXCHANGER_PROP = bytes32("exchanger");

    constructor(address _tokenAddress, address _whitelistAddress, bool _allowOperators, bool _allowExchangers)
    TokenModule(_tokenAddress, "restrictSender")
    public
    {
        require(_allowOperators || _allowExchangers, "You need to allow at least one type of users");

        whitelistAddress = _whitelistAddress;
        allowOperators = _allowOperators;
        allowExchangers = _allowExchangers;
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
            allowExchangers && operator == address(0) && whitelist.getProperty(from, EXCHANGER_PROP) == 1
        ) {
            return (0xA1, "Approved");
        } else {
            return (0xA5, "Sender is restricted");
        }
    }
}

contract RestrictSenderTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, address _whitelistAddress, bool _allowOperators, bool _allowExchangers)
    public returns(address)
    {
        RestrictSenderTokenModule instance = new RestrictSenderTokenModule(_tokenAddress, _whitelistAddress, _allowOperators, _allowExchangers);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}