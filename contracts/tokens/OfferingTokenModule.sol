pragma solidity ^0.4.24;

import "../utils/Factory.sol";
import "./TokenModule.sol";

contract OfferingTokenModule is TransferValidatorTokenModule,TokenModule {
    uint256 public start;
    uint256 public end;
    bool public exchangeByEther;
    uint256 public etherRatio;

    constructor(address _tokenAddress, uint256 _start, uint256 _end, bool _exchangeByEther, uint256 etherRatio)
    TokenModule(_tokenAddress)
    public
    {
        start = _start;
        end = _end;
        exchangeByEther = _exchangeByEther;
        etherRatio = _etherRatio;
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](1);
        features[0] = TokenModule.Feature.TransferValidator;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address from, address, uint256 amount, bytes, bytes)
    public view returns (byte, string)
    {
        // TODO we need to only allow issuance if we are between start and end
        return (0xA1, "Approved");
    }
}

contract OfferingTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _start, uint256 _end, bool _exchangeByEther, uint256 _etherRatio)
    public returns(address)
    {
        OfferingTokenModule instance = new OfferingTokenModule(_tokenAddress, _start, _end, _exchangeByEther, _etherRatio);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}