pragma solidity ^0.4.24;

import "../utils/Factory.sol";
import "./TokenModule.sol";

contract ForcedTransferTokenModule is TransferValidatorTokenModule,TransferListenerTokenModule,TokenModule {
    struct ForcedTransfer {
        bytes32 fromTranche;
        bytes32 toTranche;
        address operator;
        address from;
        address to;
        uint256 amount;
    }

    mapping(bytes32 => ForcedTransfer) pendingForceTransfers;
    uint256 numberOfPendingTransfers;

    constructor(address _tokenAddress)
    TokenModule(_tokenAddress, "forcedTransfer")
    public
    {
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](2);
        features[0] = TokenModule.Feature.TransferValidator;
        features[1] = TokenModule.Feature.TransferListener;
        return features;
    }

    function approveForcedTransfer(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount)
    onlyTokenOwner
    public
    {
        require(from != address(0), "Invalid source address");
        require(to != address(0), "Invalid destination address");
        require(operator != address(0), "Invalid operator");
        require(amount >= 0, "Negative amount");

        bytes memory hashBytes = abi.encodePacked(fromTranche, toTranche, operator, from, to, amount);
        bytes32 hash = keccak256(hashBytes);
        if (pendingForceTransfers[hash].from == address(0)) {
            pendingForceTransfers[hash].fromTranche = fromTranche;
            pendingForceTransfers[hash].toTranche = toTranche;
            pendingForceTransfers[hash].operator = operator;
            pendingForceTransfers[hash].from = from;
            pendingForceTransfers[hash].to = to;
            pendingForceTransfers[hash].amount = amount;
            numberOfPendingTransfers++;
            emit ApprovedForcedTransfer(fromTranche, toTranche, operator, from, to, amount, hash);
        }
    }

    function revokeForcedTransfer(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount)
    onlyTokenOwner
    public
    {
        require(from != address(0), "Invalid source address");
        require(to != address(0), "Invalid destination address");
        require(operator != address(0), "Invalid operator");
        require(amount >= 0, "Negative amount");

        bytes memory hashBytes = abi.encodePacked(fromTranche, toTranche, operator, from, to, amount);
        bytes32 hash = keccak256(hashBytes);
        if (pendingForceTransfers[hash].from != address(0)) {
            delete pendingForceTransfers[hash];
            numberOfPendingTransfers--;
            emit RevokedForcedTransfer(fromTranche, toTranche, operator, from, to, amount, hash);
        }
    }

    function validateTransfer(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount, bytes, bytes)
    public view returns (byte, string)
    {
        if (numberOfPendingTransfers > 0) {
            bytes memory hashBytes = abi.encodePacked(fromTranche, toTranche, operator, from, to, amount);
            bytes32 hash = keccak256(hashBytes);
            ForcedTransfer storage forcedTransfer = pendingForceTransfers[hash];
            // we check one attribute to see if it exists
            if (forcedTransfer.from == from) {
                return (0xAF, "Forced transfer");
            }
        }
        // if it is not forced, we still returned approved
        return (0xA1, "Approved");
    }

    function transferDone(bytes32 fromTranche, bytes32 toTranche, address operator, address from, address to, uint256 amount, bytes, bytes)
    public
    {
        if (numberOfPendingTransfers == 0) {
            // no need to check this
            return;
        }
        bytes memory hashBytes = abi.encodePacked(fromTranche, toTranche, operator, from, to, amount);
        bytes32 hash = keccak256(hashBytes);
        if (pendingForceTransfers[hash].from != address(0)) {
            emit ExecutedForcedTransfer(fromTranche, toTranche, operator, from, to, amount, hash);
            delete pendingForceTransfers[hash];
            numberOfPendingTransfers--;
        }
    }

    event ApprovedForcedTransfer(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address to, uint256 amount, bytes32 hash);
    event RevokedForcedTransfer(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address to, uint256 amount, bytes32 hash);
    event ExecutedForcedTransfer(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address to, uint256 amount, bytes32 hash);
}

contract ForcedTransferTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress)
    public returns(address)
    {
        ForcedTransferTokenModule instance = new ForcedTransferTokenModule(_tokenAddress);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}