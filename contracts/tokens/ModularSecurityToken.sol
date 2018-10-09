pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/ERC1411.sol";
import "../utils/Factory.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ModularTokenLib.sol";
import "./ModularERC20Lib.sol";
import "./ModularERC777Lib.sol";
import "./ModularERC1410Lib.sol";
import "./ModularERC1411Lib.sol";

contract ModularSecurityToken is ERC1411,Ownable {
    using SafeMath for uint256;
    using ModularERC20Lib for ModularTokenLib.TokenStorage;
    using ModularERC777Lib for ModularTokenLib.TokenStorage;
    using ModularERC1410Lib for ModularTokenLib.TokenStorage;
    using ModularERC1411Lib for ModularTokenLib.TokenStorage;

    enum TokenStatus {Draft, Released}

    string _name;
    string _symbol;
    uint8 _decimals;
    TokenStatus _status;
    ModularTokenLib.TokenStorage tokenStorage;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Modifiers
    //
    ///////////////////////////////////////////////////////////////////////////

    modifier isReleased()
    {
        require(_status == TokenStatus.Released, "Token must be released");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-20 Standard Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function totalSupply()
    public view returns(uint256)
    {
        return tokenStorage._totalSupply();
    }

    function balanceOf(address owner)
    public view returns (uint256)
    {
        return tokenStorage._balanceOf(owner);
    }

    function transfer(address to, uint256 value)
    isReleased
    public returns (bool)
    {
        return tokenStorage._transfer(to, value);
    }

    function allowance(address owner, address spender)
    isReleased
    public view returns (uint256)
    {
        return tokenStorage._allowance(owner, spender);
    }

    function transferFrom(address from, address to, uint256 value)
    isReleased
    public returns (bool)
    {
        return tokenStorage._transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
    isReleased
    public returns (bool)
    {
        return tokenStorage._approve(spender, value);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-777 Advanced Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function name()
    external view returns(string)
    {
        return _name;
    }

    function symbol()
    external view returns(string)
    {
        return _symbol;
    }

    function decimals()
    external view returns(uint8)
    {
        return _decimals;
    }

    function granularity()
    external view returns(uint256)
    {
        return tokenStorage._granularity();
    }

    function defaultOperators()
    external view returns(address[])
    {
        return tokenStorage._defaultOperators();
    }

    function authorizeOperator(address operator)
    external
    {
        tokenStorage._authorizeOperator(operator);
    }

    function revokeOperator(address operator)
    external
    {
        tokenStorage._revokeOperator(operator);
    }

    function isOperatorFor(address operator, address tokenHolder)
    external view returns (bool)
    {
        return tokenStorage._isOperatorFor(operator, tokenHolder);
    }

    function isDefaultOperator(address operator)
    external view returns (bool)
    {
        return tokenStorage._isDefaultOperator(operator);
    }

    function send(address to, uint256 amount, bytes data)
    isReleased
    external
    {
        tokenStorage._send(to, amount, data);
    }

    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external
    {
        tokenStorage._operatorSend(from, to, amount, data, operatorData);
    }

    function burn(uint256 amount, bytes data)
    isReleased
    external
    {
        tokenStorage._burn(amount, data);
    }

    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external
    {
        tokenStorage._operatorBurn(from, amount, data, operatorData);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1410 Partially Fungible Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDefaultTranches(address tokenHolder)
    external view returns (bytes32[])
    {
        return tokenStorage._getDefaultTranches(tokenHolder);
    }

    function setDefaultTranches(bytes32[] tranches)
    external
    {
        tokenStorage._setDefaultTranches(tranches);
    }

    function getDestinationTranche(bytes32 sourceTranche, address from, uint256 amount, bytes data)
    external view returns(bytes32)
    {
        return tokenStorage._getDestinationTranche(sourceTranche, from, amount, data);
    }

    function balanceOfByTranche(bytes32 tranche, address tokenHolder)
    external view returns (uint256)
    {
        return tokenStorage._balanceOfByTranche(tranche, tokenHolder);
    }

    function sendByTranche(bytes32 tranche, address to, uint256 amount, bytes data)
    isReleased
    external returns (bytes32)
    {
        return tokenStorage._sendByTranche(tranche, to, amount, data);
    }

    function sendByTranches(bytes32[] tranches, address[] tos, uint256[] amounts, bytes data)
    isReleased
    external returns (bytes32[])
    {
        return tokenStorage._sendByTranches(tranches, tos, amounts, data);
    }

    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external returns (bytes32)
    {
        return tokenStorage._operatorSendByTranche(tranche, from, to, amount, data, operatorData);
    }

    function operatorSendByTranches(bytes32[] tranches, address[] froms, address[] tos, uint256[] amounts, bytes data, bytes operatorData)
    isReleased
    external returns (bytes32[])
    {
        return tokenStorage._operatorSendByTranches(tranches, froms, tos, amounts, data, operatorData);
    }

    function tranchesOf(address tokenHolder)
    external view returns (bytes32[])
    {
        return tokenStorage._tranchesOf(tokenHolder);
    }

    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data)
    isReleased
    external
    {
        tokenStorage._redeemByTranche(tranche, amount, data);
    }

    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external
    {
        tokenStorage._operatorRedeemByTranche(tranche, tokenHolder, amount, data, operatorData);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1400 Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function canSend(address from, address to, bytes32 tranche, uint256 amount, bytes data)
    external view returns (byte, bytes32, bytes32)
    {
        return tokenStorage._canSend(from, to, tranche, amount, data);
    }

    function issuable()
    external view returns(bool)
    {
        return tokenStorage._issuable();
    }

    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data)
    isReleased
    external
    {
        return tokenStorage._issueByTranche(tranche, tokenHolder, amount, data);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // SLINGR Module Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    constructor(string __name, string __symbol, uint8 __decimals, uint256 _granularity, address[] _defaultOperators)
    public
    {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        tokenStorage.granularity = _granularity;
        tokenStorage.defaultOperators = _defaultOperators;
        tokenStorage.issuable = true;
        _status = TokenStatus.Draft;
    }

    function status()
    external view returns(TokenStatus)
    {
        return _status;
    }

    function release()
    external
    {
        require(_status == TokenStatus.Draft, "Token is not in draft status");
        require(tokenStorage._isDefaultOperator(msg.sender), "Only default operators can do this");

        _status = TokenStatus.Released;
    }
}


contract ModularSecurityTokenFactory is Factory {
    function createInstance(string name, string symbol, uint8 decimals, uint256 granularity, address[] defaultOperators)
    public returns(address)
    {
        ModularSecurityToken instance = new ModularSecurityToken(name, symbol, decimals, granularity, defaultOperators);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}