pragma solidity ^0.4.24;

import "./TokenModule.sol";
import "../whitelists/Whitelist.sol";
import "../utils/Factory.sol";
import "./SlingrSecurityToken.sol";

contract ReissuanceModule is TokenModule {
    event TokensReissued(address _from, address _to, uint256 amount);

    constructor(address _tokenAddress)
    TokenModule(_tokenAddress)
    public
    {
    }

    function isTransferAllowed(address, address, uint256)
    public
    returns(TransferAllowanceResult) {
        return TransferAllowanceResult.Allowed;
    }

    function reissueTokens(address _from, address _to)
    public onlyTokenOwner
    {
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        uint256 balance = token.balanceOf(token);
        token.burn(_from, balance);
        token.mint(_to, balance);
        emit TokensReissued(_from, _to, balance);
    }
}

contract ReissuanceModuleFactory is Factory {
    function createInstance(address _tokenAddress)
    public returns(address)
    {
        ReissuanceModule instance = new ReissuanceModule(_tokenAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}