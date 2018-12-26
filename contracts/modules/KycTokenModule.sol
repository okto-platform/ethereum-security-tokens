pragma solidity ^0.5.0;

import "../whitelists/IWhitelist.sol";
import "../utils/Factory.sol";
import "../tokens/TokenModule.sol";
import "./Module.sol";

contract KycTokenModule is TransferValidatorTokenModule,TokenModule {
    address public whitelistAddress;

    bytes32 constant KYC_PROP = bytes32("kycStatus");

    constructor(address _tokenAddress)
    TokenModule(_tokenAddress, "kyc")
    public
    {
        ISecurityToken token = ISecurityToken(tokenAddress);

        whitelistAddress = token.whitelistAddress();

    }

    function getFeatures()
    public view returns(Module.Feature[] memory)
    {
        Module.Feature[] memory features = new Module.Feature[](1);
        features[0] = Module.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address, address to, uint256, bytes memory)
    public view returns (byte, string memory)
    {
        IWhitelist whitelist = IWhitelist(whitelistAddress);
        uint256 propValue = uint256(whitelist.getProperty(to, KYC_PROP));
        if (propValue == 1 || propValue == 2) {
            return (0xA1, "Approved");
        } else {
            return (0xA6, "Receiver not in whitelist");
        }
    }
}

contract KycTokenModuleFactory is Factory {
    function createInstance(address tokenAddress)
    public returns(address)
    {
        KycTokenModule instance = new KycTokenModule(tokenAddress);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        return address(instance);
    }
}
