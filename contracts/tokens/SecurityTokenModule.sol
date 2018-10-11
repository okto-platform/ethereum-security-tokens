pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SecurityToken.sol";

contract TransferValidatorTokenModule {
    function validateTransfer(bytes32 tranche, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    public view returns (byte, bytes32, bytes32);
}

contract TransferListenerTokenModule {
    function transferDone(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    public;
}

contract TranchesManagerTokenModule {
    function calculateDestinationTranche(bytes32 currentDestinationTranche, bytes32 sourceTranche, address from, uint256 amount, bytes data, bytes operatorData)
    public view returns(bytes32);
}

contract SecurityTokenModule is Ownable {
    enum Feature {TransferValidator, TransferListener, TranchesManager}

    address tokenAddress;

    modifier onlyToken {
        require(msg.sender == tokenAddress, "Only token can do this");
        _;
    }

    modifier onlyTokenOwner {
        ISecurityToken token = ISecurityToken(tokenAddress);
        require(token.owner() == msg.sender, "Only token owner can do this");
        _;
    }

    modifier onlyTokenDefaultOperator {
        ISecurityToken token = ISecurityToken(tokenAddress);
        require(token.isDefaultOperator(msg.sender), "Only default operators of the token can do this");
        _;
    }

    constructor(address _tokenAddress)
    public
    {
        tokenAddress = _tokenAddress;
    }

    function getFeatures() public view returns(Feature[]);
}