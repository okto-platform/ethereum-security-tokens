pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/ERC1400.sol";
import "../utils/Factory.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract ModularSecurityToken is ERC1400,Ownable {
    using SafeMath for uint256;

    enum TokenStatus {Draft, Released}

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public granularity;
    uint256 public totalSupply;
    mapping(address => mapping(bytes32 => uint256)) internal balancesPerTranche;
    mapping(address => uint256) internal balances;
    mapping(address => bytes32[]) internal tranches;
    mapping (address => mapping (address => uint256)) internal allowed;
    address[] public defaultOperators;
    mapping(address => mapping(address => bool)) operators;
    bool public issuable = true;
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

    function totalSupply()
    public view returns(uint256)
    {
        return totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address. This returns the sum of balances of all tranches.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner)
    public view returns (uint256)
    {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another. It will use the default tranches
     *      in order to transfer tokens. The order of default tranches is important as it
     *      it will move to the next tranche if tokens are not enough in the first tranche.
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transfer(address _to, uint256 _value)
    isReleased
    public returns (bool)
    {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(_to != address(0), "Cannot transfer to address 0x0");
        internalSend(address(0), msg.sender, _to, _value, new bytes(0), new bytes(0));
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
    isReleased
    public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value)
    isReleased
    public returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        // go through default tranches to
        // TODO see if we can refactor this so we don't copy that much code
        bytes32[] memory defaultTranches = internalGetDefaultTranches(_from);
        uint256 pendingAmount = _value;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (balancesPerTranche[_from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = balancesPerTranche[_from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                bytes32 destinationTranche = internalGetDestinationTranche(defaultTranches[i], _to, amountToSubtract, new bytes(0));
                balancesPerTranche[_from][defaultTranches[i]] = balancesPerTranche[_from][defaultTranches[i]].sub(amountToSubtract);
                balancesPerTranche[_to][destinationTranche] = balancesPerTranche[_to][destinationTranche].add(amountToSubtract);
                // TODO make sure that tranche is added to destination
                // TODO remove tranche if the balance is zero for the source
                emit SentByTranche(defaultTranches[i], destinationTranche, address(0), _from, _to, amountToSubtract, new bytes(0), new bytes(0));
            }
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value)
    isReleased
    public returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-777 Advanced Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function name()
    external view returns(string)
    {
        return name;
    }

    function symbol()
    external view returns(string)
    {
        return symbol;
    }

    function granularity()
    external view returns(uint256)
    {
        return granularity;
    }

    function defaultOperators()
    external view returns(address[])
    {
        return defaultOperators;
    }

    function authorizeOperator(address operator)
    external
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot authorize token holder");
        if (!internalIsDefaultOperator(operator)) {
            operators[msg.sender][operator] = true;
        }
        emit AuthorizedOperator(operator, msg.sender);
    }

    function revokeOperator(address operator)
    external
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot revoke token holder");
        if (!internalIsDefaultOperator(operator)) {
            operators[msg.sender][operator] = false;
        }
        emit RevokedOperator(operator, msg.sender);
    }

    function isOperatorFor(address operator, address tokenHolder)
    external view returns (bool)
    {
        return internalIsOperatorFor(operator, tokenHolder);
    }

    function internalIsOperatorFor(address operator, address tokenHolder)
    internal view returns (bool)
    {
        if (internalIsDefaultOperator(operator)) {
            return true;
        }
        return operators[tokenHolder][operator];
    }

    function isDefaultOperator(address operator)
    external view returns (bool)
    {
        return internalIsDefaultOperator(operator);
    }

    function internalIsDefaultOperator(address operator)
    internal view returns (bool)
    {
        for (uint i = 0; i < defaultOperators.length; i++) {
            if (defaultOperators[i] == operator) {
                return true;
            }
        }
        return false;
    }

    function send(address to, uint256 amount, bytes data)
    isReleased
    external
    {
        require(amount <= balances[msg.sender], "Insufficient funds");
        require(to != address(0), "Cannot transfer to address 0x0");

        internalSend(address(0), msg.sender, to, amount, data, new bytes(0));
    }

    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external
    {
        require(internalIsOperatorFor(msg.sender, from), "Invalid operator");
        require(amount <= balances[from], "Insufficient funds");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(from != address(0), "Cannot transfer from address 0x0");

        internalSend(msg.sender, from, to, amount, data, operatorData);
    }

    function internalSend(address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        // TODO if `to` is a contract we need to call function `tokensToSend`
        // TODO implement `tokensReceived`
        // TODO check granularity

        // go through default tranches to
        bytes32[] memory defaultTranches = internalGetDefaultTranches(from);
        uint256 pendingAmount = amount;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (balancesPerTranche[from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = balancesPerTranche[from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                internalSendByTranche(defaultTranches[i], operator, from, to, amountToSubtract, data, operatorData);
            }
        }

        // check that all tokens could be transferred
        require(pendingAmount == 0, "Insufficient funds in default tranches");

        // trigger events
        emit Sent(operator, from, to, amount, data, operatorData);
        emit Transfer(from, to, amount);
    }

    function burn(uint256 amount, bytes data)
    isReleased
    external
    {
        // TODO call `tokensToSend`
        require(amount <= balances[msg.sender], "Insufficient funds");

        internalBurn(address(0), msg.sender, amount, data, new bytes(0));
    }

    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData)
    isReleased
    external
    {
        require(internalIsOperatorFor(msg.sender, from), "Invalid operator");
        require(amount <= balances[msg.sender], "Insufficient funds");
        require(from != address(0), "Cannot transfer from address 0x0");

        internalBurn(msg.sender, from, amount, data, operatorData);
    }

    function internalBurn(address operator, address from, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        // TODO if `to` is a contract we need to call function `tokensToSend`
        // TODO check granularity

        // go through default tranches to
        bytes32[] memory defaultTranches = internalGetDefaultTranches(from);
        uint256 pendingAmount = amount;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (balancesPerTranche[from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = balancesPerTranche[from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                internalRedeemByTranche(defaultTranches[i], operator, from, amountToSubtract, data, operatorData);
            }
        }

        // check that all tokens could be transferred
        require(pendingAmount == 0, "Insufficient funds in default tranches");

        // trigger events
        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1410 Partially Fungible Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDefaultTranches(address _tokenHolder)
    external view returns (bytes32[])
    {
        return internalGetDefaultTranches(_tokenHolder);
    }

    function internalGetDefaultTranches(address _tokenHolder)
    internal view returns (bytes32[])
    {
        // the default implementation returns the tranches available for the token
        // holder in the order they have been added
        // TODO we should allow to override this behavior through modules
        return internalTranchesOf(_tokenHolder);
    }

    function setDefaultTranches(bytes32[])
    external
    {
        // TODO we should allow to override this behavior through a module
        revert("Feature not supported");
    }

    function getDestinationTranche(bytes32 sourceTranche, address from, uint256 amount, bytes data)
    pure external returns(bytes32)
    {
        return internalGetDestinationTranche(sourceTranche, from, amount, data);
    }

    function internalGetDestinationTranche(bytes32 sourceTranche, address, uint256, bytes)
    pure internal returns(bytes32)
    {
        // the default implementation is to transfer to the same tranche
        // TODO we should allow to override this behavior through modules
        return sourceTranche;
    }

    function balanceOfByTranche(bytes32 _tranche, address _tokenHolder)
    external view returns (uint256)
    {
        return balancesPerTranche[_tokenHolder][_tranche];
    }

    function sendByTranche(bytes32 _tranche, address _to, uint256 _amount, bytes _data)
    isReleased
    external returns (bytes32)
    {
        require(_amount <= balancesPerTranche[msg.sender][_tranche], "Insufficient funds in tranche");
        require(_to != address(0), "Cannot transfer to address 0x0");
        require(_amount >= 0, "Amount cannot be negative");

        return internalSendByTranche(_tranche, address(0), msg.sender, _to, _amount, _data, new bytes(0));
    }

    function sendByTranches(bytes32[], address[], uint256[], bytes)
    isReleased
    external returns (bytes32[])
    {
        revert("Feature not supported");
    }

    function operatorSendByTranche(bytes32 _tranche, address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData)
    isReleased
    external returns (bytes32)
    {
        require(internalIsOperatorFor(msg.sender, _from), "Invalid operator");
        require(_amount <= balancesPerTranche[_from][_tranche], "Insufficient funds in tranche");
        require(_from != address(0), "Cannot transfer from address 0x0");
        require(_to != address(0), "Cannot transfer to address 0x0");
        require(_amount >= 0, "Amount cannot be negative");

        return internalSendByTranche(_tranche, msg.sender, _from, _to, _amount, _data, _operatorData);
    }

    function internalSendByTranche(bytes32 _tranche, address _operator, address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData)
    internal returns (bytes32)
    {
        // TODO call tokensToSend if n  eeded
        // TODO call tokensReceived if needed
        // TODO call canSend

        bytes32 destinationTranche = internalGetDestinationTranche(_tranche, _to, _amount, _data);
        balancesPerTranche[_from][_tranche] = balancesPerTranche[_from][_tranche].sub(_amount);
        balancesPerTranche[_to][destinationTranche] = balancesPerTranche[_to][destinationTranche].add(_amount);
        // TODO make sure that tranche is added to destination
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        // trigger events
        emit SentByTranche(_tranche, destinationTranche, _operator, _from, _to, _amount, _data, _operatorData);
        return destinationTranche;
    }

    function operatorSendByTranches(bytes32[], address[], address[], uint256[], bytes, bytes)
    isReleased
    external returns (bytes32[])
    {
        revert("Feature not supported");
    }

    function tranchesOf(address _tokenHolder)
    external view returns (bytes32[])
    {
        return internalTranchesOf(_tokenHolder);
    }

    function internalTranchesOf(address _tokenHolder)
    internal view returns (bytes32[])
    {
        return tranches[_tokenHolder];
    }

    function redeemByTranche(bytes32 _tranche, uint256 _amount, bytes _data)
    isReleased
    external
    {
        require(_amount <= balancesPerTranche[msg.sender][_tranche], "Insufficient funds in tranche");

        internalRedeemByTranche(_tranche, address(0), msg.sender, _amount, _data, new bytes(0));
    }

    function operatorRedeemByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
    isReleased
    external
    {
        require(_amount <= balancesPerTranche[msg.sender][_tranche], "Insufficient funds in tranche");
        require(internalIsOperatorFor(msg.sender, _tokenHolder), "Invalid operator");
        require(_tokenHolder != address(0), "Cannot burn tokens from address 0x0");

        internalRedeemByTranche(_tranche, msg.sender, _tokenHolder, _amount, _data, _operatorData);
    }

    function internalRedeemByTranche(bytes32 _tranche, address _operator, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
    internal
    {
        // TODO call tokensToSend if needed
        balancesPerTranche[_tokenHolder][_tranche] = balancesPerTranche[_tokenHolder][_tranche].sub(_amount);
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        balances[_tokenHolder] = balances[_tokenHolder].sub(_amount);
        // reduce total supply of tokens
        totalSupply = totalSupply.sub(_amount);
        // trigger events
        emit BurnedByTranche(_tranche, _operator, _tokenHolder, _amount, _data, _operatorData);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1400 Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function canSend(address, address _to, bytes32 _tranche, uint256 _amount, bytes _data)
    external view returns (byte, bytes32, bytes32)
    {
        bytes32 destinationTranche = internalGetDestinationTranche(_tranche, _to, _amount, _data);
        // TODO we need to go through all the transfer modules and check if we can send
        return (0xA0, bytes32(0x0), destinationTranche);
    }

    function issuable()
    external view returns(bool)
    {
        return issuable;
    }

    function issueByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data)
    isReleased
    external
    {
        require(_tokenHolder != address(0), "Cannot issue tokens to address 0x0");
        // TODO we should only allow offering modules to do this
        require(issuable, "It is not possible to issue more tokens");
        require(internalIsDefaultOperator(msg.sender), "Only default operators can do this");

        balancesPerTranche[_tokenHolder][_tranche] = balancesPerTranche[_tokenHolder][_tranche].add(_amount);
        balances[_tokenHolder] = balances[_tokenHolder].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit IssuedByTranche(_tranche, _tokenHolder, _amount, _data);
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // SLINGR Module Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _granularity, address[] _defaultOperators)
    public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        granularity = _granularity;
        defaultOperators = _defaultOperators;
        issuable = true;
    }

    function release()
    external
    {
        require(status == TokenStatus.Draft, "Token is not in draft status");
        require(internalIsDefaultOperator(msg.sender), "Only default operators can do this");

        status = TokenStatus.Released;
    }
}


contract ModularSecurityTokenFactory is Factory {
    function createInstance(string _name, string _symbol, uint8 _decimals, uint256 _granularity, address[] _defaultOperators)
    public returns(address)
    {
        ModularSecurityToken instance = new ModularSecurityToken(_name, _symbol, _decimals, _granularity, _defaultOperators);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}