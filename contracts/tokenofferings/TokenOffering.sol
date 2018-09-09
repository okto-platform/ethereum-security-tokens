pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../tokens/SlingrSecurityToken.sol";

contract TokenOffering is Pausable {
    enum TokenOfferingStatus {Draft, InProgress, Ended}

    mapping(address => uint256) tokenAllocations;
    uint256 public totalAllocatedTokens;
    uint256 public numberOfInvestors;
    address public tokenAddress;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    address[] modules;
    TokenOfferingStatus public status;

    event TokenOfferingStarted(uint256 timestamp);
    event TokenOfferingEnded(uint256 timestamp);


    modifier onlyModule {
        bool validSender = false;
        for (uint i = 0; i < modules.length; i++) {
            if (modules[i] == msg.sender) {
                validSender = true;
                break;
            }
        }
        require(validSender, "Only a module can execute this operation");
        _;
    }

    modifier draft() {
        require(status == TokenOfferingStatus.Draft, "Token offering must be in draft to execute this operation");
        _;
    }

    modifier inProgress() {
        require(status == TokenOfferingStatus.InProgress, "Token offering must be in progress to execute this operation");
        _;
    }

    modifier ended() {
        require(status == TokenOfferingStatus.Ended, "Token offering must be ended to execute this operation");
        _;
    }

    constructor(address _tokenAddress)
    public
    {
        require(_tokenAddress != address(0), "Token address must be provided");
        // TODO probably we should verify the address is the one for a token contract
        tokenAddress = _tokenAddress;
        status = TokenOfferingStatus.Draft;
    }

    function allocateTokens(address _to, uint256 _amount)
    internal inProgress
    {
        require(_to != address(0), "Address is not valid");
        require(_amount > 0, "Amount must be greater than zero");
        // TODO run validations here
        // TODO we should use the safe math library here
        uint256 currentTokensAllocation = tokenAllocations[_to];
        if (currentTokensAllocation == 0) {
            numberOfInvestors++;
        }
        tokenAllocations[_to] = currentTokensAllocation + _amount;
        totalAllocatedTokens += _amount;
        mint(_to, _amount);
        // TODO run hooks after tokens have been allocated
    }

    function mint(address _to, uint256 _amount)
    internal
    {
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        token.mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount)
    internal
    {
        // TODO check balances before burning tokens
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        totalAllocatedTokens -= _amount;
        token.burn(_to, _amount);
    }

    function start()
    public onlyOwner draft
    {
        startTimestamp = now;
        status = TokenOfferingStatus.InProgress;
        emit TokenOfferingStarted(startTimestamp);
    }

    function end()
    public onlyOwner inProgress
    {
        endTimestamp = now;
        status = TokenOfferingStatus.Ended;
        emit TokenOfferingEnded(endTimestamp);
    }

    function addModule(address _moduleAddress)
    public onlyOwner draft
    {
        // TODO we should validate it is a valid module
        modules.push(_moduleAddress);
    }

    function removeModule(address _moduleAddress)
    public onlyOwner draft
    {
        for (uint i = 0; i < modules.length-1; i++) {
            if (modules[i] == _moduleAddress) {
                break;
            }
        }
        if (i >= modules.length) {
            return;
        }
        for (; i < modules.length-1; i++){
            modules[i] = modules[i+1];
        }
        delete modules[modules.length-1];
        modules.length--;
    }
}