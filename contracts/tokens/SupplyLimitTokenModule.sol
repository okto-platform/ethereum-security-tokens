pragma solidity ^0.5.0;

import "../utils/Factory.sol";
import "./TokenModule.sol";

contract SupplyLimitTokenModule is TransferValidatorTokenModule,TokenModule {
    uint256 public limit;

    constructor(address _tokenAddress, uint256 _limit)
    TokenModule(_tokenAddress, "supplyLimit")
    public
    {
        limit = _limit;
    }

    function getFeatures()
    public view returns(TokenModule.Feature[] memory)
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](1);
        features[0] = TokenModule.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address from, address, uint256 amount, bytes memory)
    public view returns (byte, string memory)
    {
        if (from == address(0)) {
            // this is an issuance of tokens
            SecurityToken token = SecurityToken(tokenAddress);
            if ((token.totalSupply() + amount) > limit) {
                return (0xA8, "Supply limit reached");
            }
        }
        return (0xA1, "Approved");
    }
}

contract SupplyLimitTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _limit)
    public returns(address)
    {
        SupplyLimitTokenModule instance = new SupplyLimitTokenModule(_tokenAddress, _limit);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(address(instance));
        return address(instance);
    }
}
