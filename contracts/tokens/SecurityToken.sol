pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";

contract ISecurityToken is Ownable {
    // ERC-20

    //function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC-777

    //function name() public view returns (string);
    //function symbol() public view returns (string);
    //function decimals() public view returns (uint8);
    //function defaultOperators() public view returns (address[]);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function isDefaultOperator(address operator) public view returns (bool);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    // ERC-1410

    function getDestinationTranche(bytes32 sourceTranche, address from, uint256 amount, bytes data) public view returns(bytes32);
    function balanceOfByTranche(bytes32 tranche, address tokenHolder) public view returns (uint256);
    function sendByTranche(bytes32 tranche, address to, uint256 amount, bytes data) public returns (bytes32);
    //function sendByTranches(bytes32[] tranches, address[] tos, uint256[] amounts, bytes data) public returns (bytes32[]);
    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData) public returns (bytes32);
    //function operatorSendByTranches(bytes32[] tranches, address[] froms, address[] tos, uint256[] amounts, bytes data, bytes operatorData) public returns (bytes32[]);
    function tranchesOf(address tokenHolder) public view returns (bytes32[]);
    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data) public;
    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData) public;

    event SentByTranche(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event BurnedByTranche(bytes32 tranche, address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    // ERC-1411

    //function issuable() public view returns (bool);
    function canSend(address _from, address _to, bytes32 _tranche, uint256 _amount, bytes _data) public view returns (byte, bytes32, bytes32);
    function issueByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data) public;

    event IssuedByTranche(bytes32 indexed tranche, address indexed to, uint256 amount, bytes data);
}

contract SecurityToken is ISecurityToken {
    using SafeMath for uint256;

    enum TokenStatus {Draft, Released}

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => mapping(bytes32 => uint256)) internal balancesPerTranche;
    mapping(address => uint256) internal balances;
    mapping(address => bytes32[]) internal tranches;
    address[] public defaultOperators;
    mapping(address => mapping(address => bool)) internal operators;
    bool public issuable;
    TokenStatus public status;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Modifiers
    //
    ///////////////////////////////////////////////////////////////////////////

    modifier isReleased()
    {
        require(status == TokenStatus.Released, "Token must be released");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-20 Standard Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function balanceOf(address owner)
    public view returns (uint256)
    {
        return balanceOf(owner);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-777 Advanced Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function authorizeOperator(address operator)
    public
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot authorize token holder");

        if (!isDefaultOperator(operator)) {
            operators[msg.sender][operator] = true;
        }
        emit AuthorizedOperator(operator, msg.sender);
    }

    function revokeOperator(address operator)
    public
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot revoke token holder");

        if (!isDefaultOperator(operator)) {
            operators[msg.sender][operator] = false;
        }
        emit RevokedOperator(operator, msg.sender);
    }

    function isOperatorFor(address operator, address tokenHolder)
    public view returns (bool)
    {
        if (isDefaultOperator(operator)) {
            return true;
        }
        return operators[tokenHolder][operator];
    }

    function isDefaultOperator(address operator)
    public view returns (bool)
    {
        for (uint i = 0; i < defaultOperators.length; i++) {
            if (defaultOperators[i] == operator) {
                return true;
            }
        }
        return false;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1410 Partially Fungible Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDestinationTranche(bytes32 sourceTranche, address, uint256, bytes)
    public view returns(bytes32)
    {
        // the default implementation is to transfer to the same tranche
        // TODO we should allow to override this behavior through modules
        return sourceTranche;
    }

    function balanceOfByTranche(bytes32 tranche, address tokenHolder)
    public view returns (uint256)
    {
        return balancesPerTranche[tokenHolder][tranche];
    }

    function sendByTranche(bytes32 tranche, address to, uint256 amount, bytes data)
    isReleased
    public returns (bytes32)
    {
        require(amount <= balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(amount >= 0, "Amount cannot be negative");

        return internalSendByTranche(tranche, address(0), msg.sender, to, amount, data, new bytes(0));
    }

    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData)
    isReleased
    public returns (bytes32)
    {
        require(isOperatorFor(msg.sender, from), "Invalid operator");
        require(amount <= balancesPerTranche[from][tranche], "Insufficient funds in tranche");
        require(from != address(0), "Cannot transfer from address 0x0");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(amount >= 0, "Amount cannot be negative");

        return internalSendByTranche(tranche, msg.sender, from, to, amount, data, operatorData);
    }

    function internalSendByTranche(bytes32 tranche, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    internal returns (bytes32)
    {
        // TODO call tokensToSend if n  eeded
        // TODO call tokensReceived if needed
        // TODO call canSend

        bytes32 destinationTranche = getDestinationTranche(tranche, to, amount, data);
        balancesPerTranche[from][tranche] = balancesPerTranche[from][tranche].sub(amount);
        balancesPerTranche[to][destinationTranche] = balancesPerTranche[to][destinationTranche].add(amount);
        // TODO make sure that tranche is added to destination
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        // trigger events
        emit SentByTranche(tranche, destinationTranche, operator, from, to, amount, data, operatorData);
        // TODO trigger Transfer event for ERC-20 compatibilitiy
        return destinationTranche;
    }

    function tranchesOf(address tokenHolder)
    public view returns (bytes32[])
    {
        return tranches[tokenHolder];
    }

    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data)
    isReleased
    public
    {
        require(amount <= balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");

        internalRedeemByTranche(tranche, address(0), msg.sender, amount, data, new bytes(0));
    }

    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    isReleased
    public
    {
        require(amount <= balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");
        require(isOperatorFor(msg.sender, tokenHolder), "Invalid operator");
        require(tokenHolder != address(0), "Cannot burn tokens from address 0x0");

        internalRedeemByTranche(tranche, msg.sender, tokenHolder, amount, data, operatorData);
    }

    function internalRedeemByTranche(bytes32 tranche, address operator, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        // TODO call tokensToSend if needed
        balancesPerTranche[tokenHolder][tranche] = balancesPerTranche[tokenHolder][tranche].sub(amount);
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        balances[tokenHolder] = balances[tokenHolder].sub(amount);
        // reduce total supply of tokens
        totalSupply = totalSupply.sub(amount);
        // trigger events
        emit BurnedByTranche(tranche, operator, tokenHolder, amount, data, operatorData);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1411 Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function canSend(address, address to, bytes32 tranche, uint256 amount, bytes data)
    public view returns (byte, bytes32, bytes32)
    {
        bytes32 destinationTranche = getDestinationTranche(tranche, to, amount, data);
        // TODO we need to go through all the transfer modules and check if we can send
        return (0xA0, bytes32(0x0), destinationTranche);
    }

    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data)
    isReleased
    public
    {
        require(tokenHolder != address(0), "Cannot issue tokens to address 0x0");
        // TODO we should only allow offering modules to do this
        require(issuable, "It is not possible to issue more tokens");
        require(isDefaultOperator(msg.sender), "Only default operators can do this");

        balancesPerTranche[tokenHolder][tranche] = balancesPerTranche[tokenHolder][tranche].add(amount);
        balances[tokenHolder] = balances[tokenHolder].add(amount);
        totalSupply = totalSupply.add(amount);

        emit IssuedByTranche(tranche, tokenHolder, amount, data);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // SLINGR Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    constructor(string _name, string _symbol, uint8 _decimals, address[] _defaultOperators)
    public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        defaultOperators = _defaultOperators;
        issuable = true;
        status = TokenStatus.Draft;
    }

    function status()
    public view returns(TokenStatus)
    {
        return status;
    }

    function release()
    public
    {
        require(status == TokenStatus.Draft, "Token is not in draft status");
        require(isDefaultOperator(msg.sender), "Only default operators can do this");

        status = TokenStatus.Released;
    }
}


contract SecurityTokenFactory is Factory {
    function createInstance(string name, string symbol, uint8 decimals, address[] defaultOperators)
    public returns(address)
    {
        SecurityToken instance = new SecurityToken(name, symbol, decimals, defaultOperators);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}