pragma solidity ^0.4.24;

import "../utils/Factory.sol";
import "./TokenModule.sol";

contract InvestorsLimitTokenModule is TransferValidatorTokenModule,TokenModule {
    uint256 public limit;
    uint256 public numberOfInvestors;

    constructor(address _tokenAddress, uint256 _limit)
    TokenModule(_tokenAddress)
    public
    {
        require(_limit > 0, "Limit must be greater than zero");

        limit = _limit;
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
        SecurityToken token = SecurityToken(token);
        if (token.balanceOf(to) == 0) {
            // this is a new investor so we need to check limit
            if (limit <= (numberOfInvestors + 1)) {
                return (0xA8, "Maximum number of investors reached");
            }
        }
        return (0xA1, "Approved");
    }
}

contract InvestorsLimitTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _limit)
    public returns(address)
    {
        InvestorsLimitTokenModule instance = new InvestorsLimitTokenModule(_tokenAddress, _limit);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}