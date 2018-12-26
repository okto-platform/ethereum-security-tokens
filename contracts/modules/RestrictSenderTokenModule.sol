pragma solidity ^0.5.0;

import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";
import "../tokens/TokenModule.sol";
import "./Module.sol";

contract RestrictSenderTokenModule is TransferValidatorTokenModule,TokenModule {
    address public whitelistAddress;
    bool public allowOperators;
    bool public allowAts;

    bytes32 constant ATS_PROP = bytes32("ats");

    constructor(address _tokenAddress, bool _allowOperators, bool _allowAts)
    TokenModule(_tokenAddress, "restrictSender")
    public
    {
        require(_allowOperators || _allowAts, "You need to allow at least one type of users");

        ISecurityToken token = ISecurityToken(tokenAddress);
        whitelistAddress = token.whitelistAddress();
        allowOperators = _allowOperators;
        allowAts = _allowAts;
    }

    function getFeatures()
    public view returns(Module.Feature[] memory)
    {
        Module.Feature[] memory features = new Module.Feature[](1);
        features[0] = Module.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address operator, address from, address, uint256, bytes memory)
    public view returns (byte, string memory)
    {
        IWhitelist whitelist = IWhitelist(whitelistAddress);
        if (
            allowOperators && operator != address(0) ||
            allowAts && operator == address(0) && whitelist.getProperty(from, ATS_PROP) == bytes32(uint256(1))
        ) {
            return (0xA1, "Approved");
        } else {
            return (0xA5, "Sender is restricted");
        }
    }
}

contract RestrictSenderTokenModuleFactory is Factory {
    function createInstance(address tokenAddress, bool allowOperators, bool allowAts)
    public returns(address)
    {
        RestrictSenderTokenModule instance = new RestrictSenderTokenModule(tokenAddress, allowOperators, allowAts);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        return address(instance);
    }
}
