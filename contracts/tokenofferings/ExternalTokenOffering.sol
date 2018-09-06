pragma solidity ^0.4.24;

import "./TokenOffering.sol";

contract ExternalTokenOffering is TokenOffering {
    constructor(address _tokenAddress)
    TokenOffering(_tokenAddress)
    public
    {

    }

    function allocateSoldTokens(address _to, uint256 _amount)
    public onlyOwner
    {
        allocateTokens(_to, _amount);
    }

    function allocateManySoldTokens(address[] _to, uint256[] _amount)
    public onlyOwner
    {
        require(_to.length == _amount.length, "Arrays size does not match");
        for (uint i = 0; i < _to.length; i++) {
            allocateTokens(_to[i], _amount[i]);
        }
    }
}

contract ExternalTokenOfferingFactory is Factory {
    function createInstance(address _tokensAddress)
    public returns(address)
    {
        ExternalTokenOffering instance = new ExternalTokenOffering(_tokensAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}