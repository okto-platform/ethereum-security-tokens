pragma solidity ^0.4.24;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SlingrSecurityToken.sol";

contract TokenModule is Ownable {
    enum TransferAllowanceResult {NotAllowed, Allowed, ForceNotAllowed, ForceAllowed}

    address tokenAddress;

    modifier onlyTokenOwner()
    {
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        require(msg.sender == token.owner(), "Only token owner can execute this operation");
        _;
    }

    constructor(address _tokenAddress)
    public
    {
        tokenAddress = _tokenAddress;
    }

    function isTransferAllowed(address _from, address _to, uint256 _amount)
    public returns(TransferAllowanceResult);
}