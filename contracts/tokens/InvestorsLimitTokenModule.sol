pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/Factory.sol";
import "./TokenModule.sol";
import "../whitelists/Whitelist.sol";
import "../whitelists/WhitelistModule.sol";

contract InvestorsLimitTokenModule is TransferValidatorTokenModule,TransferListenerTokenModule,TokenModule,WhitelistModule {
    using SafeMath for uint256;

    uint256 public limit;
    uint256 public numberOfInvestors;
    bytes32 investorIdProperty;
    mapping(bytes32 => uint256) balancePerInvestor;

    constructor(address _tokenAddress, uint256 _limit, address _whitelistAddress, bytes32 _investorIdProperty)
    TokenModule(_tokenAddress, "investorsLimit")
    WhitelistModule(_whitelistAddress, "investorsLimit")
    public
    {
        require(_limit > 0, "Limit must be greater than zero");
        require(_whitelistAddress == address(0) || _investorIdProperty != bytes32(0), "Investor ID property must be defined");

        limit = _limit;
        investorIdProperty = _investorIdProperty;
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
        uint256 diff;
        if (whitelistAddress != address(0)) {
            // validate using balance per investor
            Whitelist whitelist = Whitelist(whitelistAddress);
            bytes32 fromInvestorId;
            bytes32 toInvestorId;
            if (from != address(0)) {
                fromInvestorId = whitelist.getProperty(from, investorIdProperty);
            }
            if (to != address(0)) {
                toInvestorId = whitelist.getProperty(to, investorIdProperty);
            }
            if (to != address(0) && balancePerInvestor[toInvestorId] == 0) {
                // if the sender is transferring all its tokens, then we can assume there will be one investor less
                diff = (from != address(0) && balancePerInvestor[fromInvestorId] == amount) ? 1 : 0;
                // this is a new investor so we need to check limit
                if ((numberOfInvestors - diff) >= limit) {
                    return (0xA8, "Maximum number of investors reached");
                }
            }
        } else {
            if (to != address(0) && token.balanceOf(to) == 0) {
                // if the sender is transferring all its tokens, then we can assume there will be one investor less
                diff = (from != address(0) && token.balanceOf(from) == amount) ? 1 : 0;
                // this is a new investor so we need to check limit
                if ((numberOfInvestors - diff) >= limit) {
                    return (0xA8, "Maximum number of investors reached");
                }
            }
        }
        return (0xA1, "Approved");
    }

    function transferDone(bytes32, bytes32, address, address from, address to, uint256 amount, bytes, bytes)
    public
    {
        SecurityToken token = SecurityToken(tokenAddress);
        if (whitelistAddress != address(0)) {
            // if there is a whitelist we should take into account balancer per investor instead of per wallet
            Whitelist whitelist = Whitelist(whitelistAddress);
            bytes32 fromInvestorId;
            bytes32 toInvestorId;
            if (from != address(0)) {
                fromInvestorId = whitelist.getProperty(from, investorIdProperty);
                balancePerInvestor[fromInvestorId] = balancePerInvestor[fromInvestorId].sub(amount);
            }
            if (to != address(0)) {
                toInvestorId = whitelist.getProperty(to, investorIdProperty);
                balancePerInvestor[toInvestorId] = balancePerInvestor[toInvestorId].add(amount);
            }
            if (to != address(0) && balancePerInvestor[toInvestorId] == amount) {
                // it means that this is a new investor as all the tokens are the ones that were transferred in this operation
                numberOfInvestors++;
            }
            if (from != address(0) && balancePerInvestor[fromInvestorId] == 0) {
                // decrease the number of investors as the sender does not have any tokens after the transaction
                numberOfInvestors--;
            }
        } else {
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

    function investorUpdated(address investor, bytes32 bucket, bytes32 newValue, bytes32 oldValue)
    onlyWhitelist
    public
    {
        if (bucket == investorIdProperty && newValue != oldValue) {
            SecurityToken token = SecurityToken(tokenAddress);
            uint256 balanceOfAddress = token.balanceOf(investor);
            // move balance of the address to the new investor
            balancePerInvestor[oldValue] = balancePerInvestor[oldValue].sub(balanceOfAddress);
            balancePerInvestor[newValue] = balancePerInvestor[newValue].add(balanceOfAddress);
            if (balancePerInvestor[newValue] == balanceOfAddress) {
                // it means that this is a new investor as all the tokens are the ones that were moved in this operation
                numberOfInvestors++;
            }
            if (balancePerInvestor[oldValue] == 0) {
                // decrease the number of investors as the old investor does not have any tokens after the operation
                numberOfInvestors--;
            }
            if (numberOfInvestors > limit) {
                revert("Maximum number of investors reached");
            }
        }
    }
}

contract InvestorsLimitTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _limit, address _whitelistAddress, bytes32 _investorIdProperty)
    public returns(address)
    {
        InvestorsLimitTokenModule instance = new InvestorsLimitTokenModule(_tokenAddress, _limit, _whitelistAddress, _investorIdProperty);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        if (_whitelistAddress != address(0)) {
            Whitelist whitelist = Whitelist(_whitelistAddress);
            whitelist.addModule(instance);
        }
        return instance;
    }
}