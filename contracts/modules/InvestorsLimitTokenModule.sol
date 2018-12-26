pragma solidity ^0.5.0;

import "../utils/SafeMath.sol";
import "../utils/Factory.sol";
import "../whitelists/IWhitelist.sol";
import "../whitelists/WhitelistModule.sol";
import "../tokens/ISecurityToken.sol";
import "../tokens/TokenModule.sol";
import "./Module.sol";

contract InvestorsLimitTokenModule is TransferValidatorTokenModule,TransferListenerTokenModule,TokenModule,WhitelistModule {
    using SafeMath for uint256;

    bytes32 constant INVESTOR_ID_PROP = bytes32("investorId");

    uint256 public limit;
    bool public checkInvestorId;

    uint256 public numberOfInvestors;
    bytes32 investorIdProperty;
    mapping(bytes32 => uint256) balancePerInvestor;

    constructor(address _tokenAddress, address _whitelistAddress, uint256 _limit, bool _checkInvestorId)
    TokenModule(_tokenAddress, "investorsLimit")
    WhitelistModule(_whitelistAddress, "investorsLimit")
    public
    {
        require(_limit > 0, "Limit must be greater than zero");
        ISecurityToken token = ISecurityToken(tokenAddress);
        require(token.whitelistAddress() == _whitelistAddress, "Whitelist must be the same as the whitelist in the token");

        limit = _limit;
        checkInvestorId = _checkInvestorId;
    }

    function getFeatures()
    public view returns(Module.Feature[] memory)
    {
        Module.Feature[] memory features = new Module.Feature[](3);
        features[0] = Module.Feature.TransferValidator;
        features[1] = Module.Feature.TransferListener;
        features[2] = Module.Feature.WhitelistListener;
        return features;
    }

    function validateTransfer(bytes32, bytes32, address, address from, address to, uint256 amount, bytes memory)
    public view returns (byte, string memory)
    {
        ISecurityToken token = ISecurityToken(tokenAddress);
        uint256 diff;
        if (checkInvestorId) {
            // validate using balance per investor
            IWhitelist whitelist = IWhitelist(whitelistAddress);
            bytes32 fromInvestorId;
            bytes32 toInvestorId;
            if (from != address(0)) {
                fromInvestorId = whitelist.getProperty(from, INVESTOR_ID_PROP);
            }
            if (to != address(0)) {
                toInvestorId = whitelist.getProperty(to, INVESTOR_ID_PROP);
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

    function transferDone(bytes32, bytes32, address, address from, address to, uint256 amount, bytes memory)
    onlyToken
    public
    {
        ISecurityToken token = ISecurityToken(tokenAddress);
        if (checkInvestorId) {
            // if there is a whitelist we should take into account balancer per investor instead of per wallet
            IWhitelist whitelist = IWhitelist(whitelistAddress);
            bytes32 fromInvestorId;
            bytes32 toInvestorId;
            if (from != address(0)) {
                fromInvestorId = whitelist.getProperty(from, INVESTOR_ID_PROP);
                balancePerInvestor[fromInvestorId] = balancePerInvestor[fromInvestorId].sub(amount);
            }
            if (to != address(0)) {
                toInvestorId = whitelist.getProperty(to, INVESTOR_ID_PROP);
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
        if (bucket == INVESTOR_ID_PROP && newValue != oldValue) {
            ISecurityToken token = ISecurityToken(tokenAddress);
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
    function createInstance(address tokenAddress, uint256 limit, bool checkInvestorId)
    public returns(address)
    {
        ISecurityToken token = ISecurityToken(tokenAddress);
        address whitelistAddress = token.whitelistAddress();
        InvestorsLimitTokenModule instance = new InvestorsLimitTokenModule(tokenAddress, whitelistAddress, limit, checkInvestorId);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        return address(instance);
    }
}
