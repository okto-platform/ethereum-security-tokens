pragma solidity ^0.4.24;

import "../utils/Factory.sol";
import "./TokenModule.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract OfferingTokenModule is TransferValidatorTokenModule,TokenModule,Pausable {
    uint256 public start;
    uint256 public end;

    constructor(address _tokenAddress, uint256 _start, uint256 _end)
    TokenModule(_tokenAddress, "offering")
    public
    {
        start = _start;
        end = _end;
    }

    function getFeatures()
    public view returns(TokenModule.Feature[])
    {
        TokenModule.Feature[] memory features = new TokenModule.Feature[](1);
        features[0] = TokenModule.Feature.TransferValidator;
        return features;
    }

    function issueTokens(bytes32[] tranches, address[] investors, uint256[] amounts)
    onlyTokenDefaultOperator whenNotPaused
    public
    {
        require(investors.length == tranches.length && tranches.length == amounts.length, "");
        require(investors.length > 0, "Tokens for at least one investor should be issued");
        require(now >= start, "The offering has not started yet");
        require(now <= end, "The offering has finished already");
        byte res;
        string memory message;
        SecurityToken token = SecurityToken(tokenAddress);
        for (uint i = 0; i < investors.length; i++) {
            (res, message, ) = token.canSend(tranches[i], msg.sender, address(0), investors[i], amounts[i], new bytes(0), abi.encodePacked("issuing"));
            if (res != 0xA0 && res != 0xA1 && res != 0xA2 && res != 0xAF) {
                emit TokenAllocationError(i, res, message);
            } else {
                token.issueByTranche(tranches[i], investors[i], amounts[i], abi.encodePacked("issuing"));
            }
        }
    }

    function reserveTokens(bytes32[] tranches, address[] investors, uint256[] amounts)
    onlyTokenOwner whenNotPaused
    public
    {
        require(investors.length == tranches.length && tranches.length == amounts.length, "Number of investors, tranches and amounts does not match");
        require(investors.length > 0, "Tokens for at least one investor should be issued");

        byte res;
        string memory message;
        SecurityToken token = SecurityToken(tokenAddress);
        for (uint i = 0; i < investors.length; i++) {
            (res, message, ) = token.canSend(tranches[i], msg.sender, address(0), investors[i], amounts[i], new bytes(0), abi.encodePacked("reservation"));
            if (res != 0xA0 && res != 0xA1 && res != 0xA2 && res != 0xAF) {
                emit TokenAllocationError(i, res, message);
            } else {
                token.issueByTranche(tranches[i], investors[i], amounts[i], abi.encodePacked("reservation"));
            }
        }
    }

    function validateTransfer(bytes32, bytes32, address, address from, address to, uint256, bytes, bytes operatorData)
    public view returns (byte, string)
    {
        if (from == address(0)) {
            // if this is a token reservation (only done by the owner of the token) we don't perform this validation
            if (keccak256(operatorData) != keccak256(abi.encodePacked("reservation"))) {
                // we need to only allow issuance if we are between start and end
                if (now < start || now > end) {
                    return (0xA8, "Offering not in progress");
                }
            }
            // if offering is in progress, but it is paused we will return an error
            if (now >= start && now <= end && paused) {
                return (0xA8, "Offering is paused");
            }
        } else if (to != address(0)) {
            // if this is a regular transfer and not issuance, we will reject it if the offering is not finished
            if (now <= end) {
                return (0xA8, "Transfers are not allowed until offering is finished");
            }
        }
        return (0xA1, "Approved");
    }

    event TokenAllocationError(uint256 index, byte code, string errorMessage);
}

contract OfferingTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _start, uint256 _end)
    public returns(address)
    {
        OfferingTokenModule instance = new OfferingTokenModule(_tokenAddress, _start, _end);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}