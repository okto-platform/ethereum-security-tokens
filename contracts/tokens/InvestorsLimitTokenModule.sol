pragma solidity ^0.4.24;

import "../utils/Factory.sol";
import "./TokenModule.sol";

contract InvestorsLimitTokenModule is TransferValidatorTokenModule,TransferListenerTokenModule,TokenModule {
    uint256 public limit;
    uint256 public numberOfInvestors;

    constructor(address _tokenAddress, uint256 _limit)
    TokenModule(_tokenAddress)
    public
    {
        require(_limit > 0, "Limit must be greater than zero");

        limit = _limit;
        type = "investorsLimit";
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](2);
        features[0] = TokenModule.Feature.TransferValidator;
        features[1] = TokenModule.Feature.TransferListener;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address from, address to, uint256 amount, bytes, bytes)
    public view returns (byte, string)
    {
        SecurityToken token = SecurityToken(tokenAddress);
        if (to != address(0) && token.balanceOf(to) == 0) {
            // if the sender is transferring all its tokens, then we can assume there will be one investor less
            uint256 diff = (from != address(0) && token.balanceOf(from) == amount) ? 1 : 0;
            // this is a new investor so we need to check limit
            if ((numberOfInvestors - diff) >= limit) {
                return (0xA8, "Maximum number of investors reached");
            }
        }
        return (0xA1, "Approved");
    }

    function transferDone(bytes32, bytes32, address, address from, address to, uint256 amount, bytes, bytes)
    public
    {
        SecurityToken token = SecurityToken(tokenAddress);
        if (to != address(0) && token.balanceOf(to) == amount) {
            // it means that this is a new investor as all the tokens are the ones that were transferred in this operation
            numberOfInvestors++;
        }
        if (from != address(0) && token.balanceOf(from) == 0) {
            // decrease the number of investors as the sender does not have any tokens after the transaction
            numberOfInvestors--;
        }
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