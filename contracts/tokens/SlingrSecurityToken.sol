pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./TokenModule.sol";
import "../utils/Factory.sol";

contract SlingrSecurityToken is StandardToken,Ownable {
    enum TokenStatus {Draft, Released}

    string public name;
    string public symbol;
    uint8 public decimals;
    address tokenOfferingAddress;
    address[] modules;
    TokenStatus status;

    event TokenReleased();
    event TokensMinted(address to, uint256 amount);
    event TokensBurned(address from, uint256 amount);

    modifier onlyTokenOffering {
        require(msg.sender == tokenOfferingAddress, "Only token offering can execute this operation");
        _;
    }

    modifier onlyModuleOrTokenOffering {
        bool validSender = msg.sender == tokenOfferingAddress;
        if (!validSender) {
            for (uint i = 0; i < modules.length; i++) {
                if (modules[i] == msg.sender) {
                    validSender = true;
                    break;
                }
            }
        }
        require(validSender, "Only token offering or token module can execute this operation");
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

    constructor(string _name, string _symbol, uint8 _decimals)
    public
    {
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
    public onlyModuleOrTokenOffering released
    {
        // TODO maybe we should have special hooks for minitng, but I think those should be in the offering
        balances[_to] = balances[_to].add(_amount);
        emit TokensMinted(_to, _amount);
    }

    function burn(address _from, uint256 _amount)
    public onlyModuleOrTokenOffering released
    {
        // TODO only token offering contract can call this method
        require(balances[_from] >= _amount, "Tokens to burn exceeded the balance of the wallet");
        balances[_from] = balances[_from].sub(_amount);
        emit TokensBurned(_from, _amount);
    }

    function setTokenOffering(address _tokenOfferingAddress)
    public onlyOwner draft
    {
        // TODO we should try to call a method to verify it is a token offering contract
        tokenOfferingAddress = _tokenOfferingAddress;
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