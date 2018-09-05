pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./TokenModule.sol";
import "../utils/Factory.sol";

contract SlingrSecurityToken is StandardToken,Ownable {
    enum TokenStatus {Draft, Released}

    string name;
    string symbol;
    uint8 decimals;
    address tokenOfferingAddress;
    TokenModule[] modules;
    TokenStatus status;

    event TokenReleased();
    event TokenOfferingAttached(address tokenOfferingAddress);
    event ModuleAdded(address moduleAddress, string moduleName);
    event ModuleRemoved(address moduleAddress, string moduleName);

    modifier onlyTokenOffering {
        require(msg.sender == tokenOfferingAddress);
        _;
    }

    modifier draft() {
        require(status == TokenStatus.Draft, "Token must be in draft to execute this operation");
        _;
    }

    modifier released() {
        require(status == TokenStatus.Released, "Token must be released to execute this operation");
        _;
    }

    constructor(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        status = TokenStatus.Draft;
    }

    function transfer(address _to, uint256 _value)
    public released returns(bool)
    {
        bool allowTransfer = validateTransfer(msg.sender, _to, _value);
        if (allowTransfer) {
            return super.transfer(_to, _value);
        } else {
            revert("Transfer is not allowed");
        }
    }


    function transferFrom(address _from, address _to, uint256 _value)
    public released returns(bool)
    {
        bool allowTransfer = validateTransfer(_from, _to, _value);
        if (allowTransfer) {
            return super.transferFrom(_from, _to, _value);
        } else {
            revert("Transfer is not allowed");
        }
    }

    function validateTransfer(address _from, address _to, uint256 _value)
    internal released returns(bool)
    {
        bool allowTransfer = true;
        for (uint8 i = 0; i < modules.length; i++) {
            TokenModule module = TokenModule(modules[i]);
            TokenModule.TransferAllowanceResult result = module.isTransferAllowed(_from, _to, _value);
            if (result == TokenModule.TransferAllowanceResult.ForceAllowed) {
                allowTransfer = true;
                break;
            } else if (result == TokenModule.TransferAllowanceResult.ForceNotAllowed) {
                allowTransfer = false;
                break;
            } else if (result == TokenModule.TransferAllowanceResult.Allowed) {
                // we don't do anything in this case
            } else if (result == TokenModule.TransferAllowanceResult.ForceNotAllowed) {
                allowTransfer = false;
            } else {
                revert("Wrong response from module");
            }
        }
        return allowTransfer;
    }

    function mint(address _to, uint256 _amount)
    public onlyTokenOffering released
    {
        // TODO only token offering contract can call this method
    }

    function burn(address _to, uint256 _amount)
    public onlyTokenOffering released
    {
        // TODO only token offering contract can call this method
    }

    function setTokenOffering(address _tokenOfferingAddress)
    public onlyOwner draft
    {
        tokenOfferingAddress = _tokenOfferingAddress;
        // TODO we should try to call a method to verify it is a token offering contract
        emit TokenOfferingAttached(tokenOfferingAddress);
    }

    function addModule(address _moduleAddress)
    public onlyOwner draft
    {
        // TODO we should verify it is a valid module
        modules.push(_moduleAddress);
    }

    function removeModule(address _moduleAddress)
    public onlyOwner draft
    {
        // TODO implement this method
    }

    function release()
    public onlyOwner draft
    {
        status = TokenStatus.Released;
        emit TokenReleased();
    }
}


contract SlingrSecurityTokenFactory is Factory {
    function createInstance(string _name, string _symbol, uint8 _decimals)
    public returns(address)
    {
        SlingrSecurityToken instance = new SlingrSecurityToken(_name, _symbol, _decimals);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}