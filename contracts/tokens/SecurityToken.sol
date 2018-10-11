pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../utils/Bytes32ArrayLib.sol";

contract ISecurityToken is Pausable {
    // ERC-20

    uint256 public totalSupply;

    function balanceOf(address tokenHolder) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC-777

    string public name;
    string public symbol;
    uint8 public decimals;
    address[] public defaultOperators;

    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function isDefaultOperator(address operator) public view returns (bool);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    // ERC-1410

    function getDestinationTranche(bytes32 sourceTranche, address from, uint256 amount, bytes data, bytes operatorData) public view returns(bytes32);
    function balanceOfByTranche(bytes32 tranche, address tokenHolder) public view returns (uint256);
    function sendByTranche(bytes32 tranche, address to, uint256 amount, bytes data) public returns (bytes32);
    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData) public returns (bytes32);
    function tranchesOf(address tokenHolder) public view returns (bytes32[]);

    event SentByTranche(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);

    // ERC-1411

    function canSend(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData) public view returns (byte, bytes32, bytes32);
    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data) public;
    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data) public;
    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData) public;

    event IssuedByTranche(bytes32 indexed tranche, address indexed to, uint256 amount, bytes data);
    event RedeemedByTranche(bytes32 tranche, address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    // SLINGR Security Token

    bool public released;

    function release() public;

    event Released();
}

contract SecurityToken is ISecurityToken {
    using SafeMath for uint256;

    mapping(address => mapping(bytes32 => uint256)) internal balancesPerTranche;
    mapping(address => uint256) internal balances;
    mapping(address => bytes32[]) internal tranches;
    mapping(address => mapping(address => bool)) internal operators;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Modifiers
    //
    ///////////////////////////////////////////////////////////////////////////

    modifier isReleased()
    {
        require(released, "Token is not released");
        _;
    }

    modifier isDraft()
    {
        require(!released, "Token is already released");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-20 Standard Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function balanceOf(address tokenHolder)
    public view returns (uint256)
    {
        return balances[tokenHolder];
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

    // TODO allow to change default operators by owner

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1410 Partially Fungible Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDestinationTranche(bytes32 sourceTranche, address, uint256, bytes, bytes)
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
    isReleased whenNotPaused
    public returns (bytes32)
    {
        require(to != address(0), "Cannot transfer to address 0x0");

        return internalSendByTranche(tranche, address(0), msg.sender, to, amount, data, new bytes(0));
    }

    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData)
    isReleased whenNotPaused
    public returns (bytes32)
    {
        require(isOperatorFor(msg.sender, from), "Invalid operator");
        require(from != address(0), "Cannot transfer from address 0x0");

        return internalSendByTranche(tranche, msg.sender, from, to, amount, data, operatorData);
    }

    function internalSendByTranche(bytes32 tranche, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    internal returns (bytes32)
    {
        require(amount <= balancesPerTranche[from][tranche], "Insufficient funds in tranche");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(amount >= 0, "Amount cannot be negative");

        verifyCanSendOrRevert(tranche, msg.sender, to, amount, data, operatorData);

        bytes32 destinationTranche = getDestinationTranche(tranche, to, amount, data, operatorData);
        balancesPerTranche[from][tranche] = balancesPerTranche[from][tranche].sub(amount);
        balancesPerTranche[to][destinationTranche] = balancesPerTranche[to][destinationTranche].add(amount);
        // make sure that tranche is added to destination
        if (amount > 0) {
            Bytes32ArrayLib.addIfNotPresent(tranches[to], tranche);
        }
        // remove tranche if the balance is zero for the source
        if (balancesPerTranche[from][tranche] == 0) {
            Bytes32ArrayLib.removeValue(tranches[from], tranche);
        }
        // update global balances
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);

        // trigger events
        emit SentByTranche(tranche, destinationTranche, operator, from, to, amount, data, operatorData);
        emit Transfer(from, to, amount); // this is for compatibility with ERC-20

        return destinationTranche;
    }

    function tranchesOf(address tokenHolder)
    public view returns (bytes32[])
    {
        return tranches[tokenHolder];
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1411 Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function canSend(bytes32 tranche, address, address to, uint256 amount, bytes data, bytes operatorData)
    public view returns (byte, bytes32, bytes32)
    {
        bytes32 destinationTranche = getDestinationTranche(tranche, to, amount, data, operatorData);
        // TODO we need to go through all the transfer modules and check if we can send
        return (0xA0, bytes32(0x0), destinationTranche);
    }

    function verifyCanSendOrRevert(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData)
    internal view
    {
        byte errorCode;
        bytes32 errorInfo;
        bytes32 destTranche;

        (errorCode, errorInfo, destTranche) = canSend(tranche, from, to, amount, data, operatorData);

        // TODO we need to determine with more precision when the transaction fails
        if (errorCode != 0xA0) {
            // TODO ideally we should revert with a more precise error message
            revert("This operation is restricted");
        }
    }

    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data)
    isReleased whenNotPaused
    public
    {
        require(tokenHolder != address(0), "Cannot issue tokens to address 0x0");
        require(isDefaultOperator(msg.sender), "Only default operators can do this");

        verifyCanSendOrRevert(tranche, address(0), tokenHolder, amount, data, new bytes(0));

        balancesPerTranche[tokenHolder][tranche] = balancesPerTranche[tokenHolder][tranche].add(amount);
        balances[tokenHolder] = balances[tokenHolder].add(amount);
        if (amount > 0) {
            Bytes32ArrayLib.addIfNotPresent(tranches[tokenHolder], tranche);
        }
        totalSupply = totalSupply.add(amount);

        emit IssuedByTranche(tranche, tokenHolder, amount, data);
    }


    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data)
    isReleased whenNotPaused
    public
    {
        internalRedeemByTranche(tranche, address(0), msg.sender, amount, data, new bytes(0));
    }

    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    isReleased whenNotPaused
    public
    {
        require(isOperatorFor(msg.sender, tokenHolder), "Invalid operator");
        require(tokenHolder != address(0), "Cannot burn tokens from address 0x0");

        internalRedeemByTranche(tranche, msg.sender, tokenHolder, amount, data, operatorData);
    }

    function internalRedeemByTranche(bytes32 tranche, address operator, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        require(amount <= balancesPerTranche[tokenHolder][tranche], "Insufficient funds in tranche");

        verifyCanSendOrRevert(tranche, tokenHolder, address(0), amount, data, operatorData);

        balancesPerTranche[tokenHolder][tranche] = balancesPerTranche[tokenHolder][tranche].sub(amount);
        if (balancesPerTranche[tokenHolder][tranche] == 0) {
            Bytes32ArrayLib.removeValue(tranches[tokenHolder], tranche);
        }
        // update global balances
        balances[tokenHolder] = balances[tokenHolder].sub(amount);
        // reduce total supply of tokens
        totalSupply = totalSupply.sub(amount);
        // trigger events
        emit RedeemedByTranche(tranche, operator, tokenHolder, amount, data, operatorData);
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
    }

    function release()
    onlyOwner
    public
    {
        require(!released, "Token already released");

        released = true;

        emit Released();
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