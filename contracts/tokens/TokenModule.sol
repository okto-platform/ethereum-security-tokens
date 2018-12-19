pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SecurityToken.sol";

contract TransferValidatorTokenModule {

    // Validation codes:
    //
    // 0xA0	Transfer Verified - Unrestricted
    // 0xA1 Transfer Verified - On-Chain approval for restricted token
    // 0xA2	Transfer Verified - Off-Chain approval for restricted token
    // 0xA3	Transfer Blocked - Sender lockup period not ended
    // 0xA4	Transfer Blocked - Sender balance insufficient
    // 0xA5	Transfer Blocked - Sender not eligible
    // 0xA6	Transfer Blocked - Receiver not eligible
    // 0xA7	Transfer Blocked - Identity restriction
    // 0xA8	Transfer Blocked - Token restriction
    // 0xA9	Transfer Blocked - Token granularity
    // 0xAA Transfer Blocked - Negative amount
    // 0xAF Transfer Verified - Forced

    function validateTransfer(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount, bytes data)
    public view returns (byte, string);
}

contract TransferListenerTokenModule {
    function transferDone(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount, bytes data)
    public;
}

contract TranchesManagerTokenModule {
    function calculateDestinationTranche(bytes32 currentDestinationTranche, bytes32 sourceTranche, address from, uint256 amount, bytes data)
    public view returns(bytes32);
}

contract TokenModule is Ownable {
    enum Feature {TransferValidator, TransferListener, TranchesManager}

    address tokenAddress;
    string public moduleType;

    modifier onlyToken {
        require(msg.sender == tokenAddress, "Only token can do this");
        _;
    }

    modifier onlyTokenOwner {
        ISecurityToken token = ISecurityToken(tokenAddress);
        require(token.owner() == msg.sender, "Only token owner can do this");
        _;
    }

    modifier onlyTokenOperator {
        ISecurityToken token = ISecurityToken(tokenAddress);
        require(token.isOperator(msg.sender), "Only operators of the token can do this");
        _;
    }

    constructor(address _tokenAddress, string _moduleType)
    public
    {
        tokenAddress = _tokenAddress;
        moduleType = _moduleType;
    }

    function getFeatures() public view returns(Feature[]);
}