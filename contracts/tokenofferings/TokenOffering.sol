pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../tokens/SlingrSecurityToken.sol";

contract TokenOffering is Pausable {
    enum TokenOfferingStatus {Draft, InProgress, Ended}

    mapping(address => uint256) tokenAllocations;
    uint256 totalAllocatedTokens;
    uint256 numberOfInvestors;
    address tokenAddress;
    uint256 startTimestamp;
    uint256 endTimestamp;
    TokenOfferingStatus status;

    event TokensAllocated(address to, uint256 amount);
    event TokenOfferingStarted(uint256 timestamp);
    event TokenOfferingEnded(uint256 timestamp);

    modifier draft() {
        require(status == TokenOfferingStatus.Draft, "Token offering must be in draft to execute this operation");
        _;
    }

    modifier inProgress() {
        require(status == TokenOfferingStatus.InProgress, "Token offering must be in progress to execute this operation");
        _;
    }

    constructor() {
        status = TokenOfferingStatus.Draft;
    }

    function allocateTokens(address _to, uint256 _amount)
    internal inProgress
    {
        require(_to != address(0), "Address is not valid");
        require(_amount > 0, "Amount must be greater than zero");
        // TODO run validations here
        uint256 currentTokensAllocation = tokenAllocations[_to];
        if (currentTokensAllocation == 0) {
            numberOfInvestors++;
        }
        tokenAllocations[_to] = currentTokensAllocation + _amount;
        mint(_to, _amount);
        TokensAllocated(_to, _amount);
        // TODO run hooks after tokens have been allocated
    }

    function mint(address _to, uint256 _amount)
    internal inProgress
    {
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        token.mint(_to, _amount);
    }

    function setToken(address _tokenAddress)
    public onlyOwner draft
    {
        tokenAddress = _tokenAddress;
    }

    function start()
    public onlyOwner draft
    {
        require(tokenAddress != address(0), "Token must be associated to token offering");

        startTimestamp = now;
        status = TokenOfferingStatus.InProgress;
        TokenOfferingStarted(startTimestamp);
    }

    function end()
    public onlyOwner inProgress
    {
        endTimestamp = now;
        status = TokenOfferingStatus.Ended;
        TokenOfferingEnded(endTimestamp);
    }
}