pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/ERC1400.sol";
import "../utils/Factory.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract ModularSecurityToken is ERC1400,Ownable {
    using SafeMath for uint256;

    enum TokenStatus {Draft, Released}

    uint256 public totalSupply;
    mapping(address => mapping(bytes32 => uint256)) internal balancesPerTranche;
    mapping(address => uint256) internal balances;
    mapping(address => bytes32[]) internal tranches;
    mapping (address => mapping (address => uint256)) internal allowed;
    TokenStatus public status;

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-20 Standard Token
    //
    ///////////////////////////////////////////////////////////////////////////

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
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transfer(address _to, uint256 _value)
    public returns (bool)
    {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(_to != address(0), "Cannot transfer to address 0x0");
        send(_to, _value, new bytes[](0));
        return true;
    }

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-777 Advanced Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);

    function send(address to, uint256 amount, bytes data)
    public
    {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(_to != address(0), "Cannot transfer to address 0x0");

        // go through default tranches to
        bytes32 defaultTranches = getDefaultTranches(msg.sender);
        uint256 pendingAmount = amount;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (balancesPerTranche[msg.sender][defaultTranches[i]] > 0) {
                uint256 trancheBalance = balancesPerTranche[msg.sender][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                sendByTranche(defaultTranches[i], to, amountToSubtract, data);
            }
        }

        // check that all tokens could be transferred
        require(pendingAmount > 0, "Insufficient funds in default tranches");

        // update global balances
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Sent(address(0), msg.sender, to, amount, data, new bytes[](0));
        emit Transfer(msg.sender, _to, _value);
    }

    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData) public;

    function burn(uint256 amount, bytes data) public;
    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1410 Partially Fungible Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDefaultTranches(address _tokenHolder) external view returns (bytes32[]);
    function setDefaultTranche(bytes32[] _tranches) external;
    function balanceOfByTranche(bytes32 _tranche, address _tokenHolder) external view returns (uint256);

    function sendByTranche(bytes32 _tranche, address _to, uint256 _amount, bytes _data)
    external returns (bytes32)
    {
        require(_value <= balancesPerTranche[msg.sender][_tranche], "Insufficient funds in tranche");
        require(_to != address(0), "Cannot transfer to address 0x0");

        bytes32 destinationTranche = getDestinationTranche(_tranche, _to, _amount, _data);
        balancesPerTranche[msg.sender][_tranche] = balancesPerTranche[msg.sender][_tranche].sub(_amount);
        balancesPerTranche[to][destinationTranche] = balancesPerTranche[to][destinationTranche].add(_amount);
        // TODO make sure that tranche is added to destination
        // TODO remove tranche if the balance is zero for the source
        SentByTranche(_tranche, destinationTranche, address(0), msg.sender, _to, _amount, _data, new bytes[](0));
        return destinationTranche;
    }

    function sendByTranches(bytes32[] _tranches, address[] _tos, uint256[] _amounts, bytes _data) external returns (bytes32[]);
    function operatorSendByTranche(bytes32 _tranche, address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData) external returns (bytes32);
    function operatorSendByTranches(bytes32[] _tranches, address[] _froms, address[] _tos, uint256[] _amounts, bytes _data, bytes _operatorData) external returns (bytes32[]);
    function tranchesOf(address _tokenHolder) external view returns (bytes32[]);
    function defaultOperatorsByTranche(bytes32 _tranche) external view returns (address[]);
    function authorizeOperatorByTranche(bytes32 _tranche, address _operator) external;
    function revokeOperatorByTranche(bytes32 _tranche, address _operator) external;
    function isOperatorForTranche(bytes32 _tranche, address _operator, address _tokenHolder) external view returns (bool);
    function redeemByTranche(bytes32 _tranche, uint256 _amount, bytes _data) external;
    function operatorRedeemByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _operatorData) external;

    event SentByTranche(
        bytes32 indexed fromTranche,
        bytes32 toTranche,
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event BurnedByTranche(bytes32 indexed tranche, address indexed operator, address indexed from, uint256 amount, bytes operatorData);

    ///////////////////////////////////////////////////////////////////////////
    //
    // ERC-1400 Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDocument(bytes32 _name) external view returns (string, bytes32);
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external;
    function issuable() external view returns (bool);
    function canSend(address _from, address _to, bytes32 _tranche, uint256 _amount, bytes _data) external view returns (byte, bytes32, bytes32);
    function issueByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data) external;

    event IssuedByTranche(bytes32 indexed tranche, address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    ///////////////////////////////////////////////////////////////////////////
    //
    // SLINGR Module Security Token
    //
    ///////////////////////////////////////////////////////////////////////////

    function getDestinationTranche(bytes32 sourceTranche, address, uint256, bytes)
    public view external returns(bytes32)
    {
        // the default implementation is to transfer to the same tranche
        return sourceTranche;
    }
}


contract ModularSecurityTokenFactory is Factory {
    function createInstance(string _name, string _symbol, uint8 _decimals)
    public returns(address)
    {
        ModularSecurityToken instance = new ModularSecurityToken(_name, _symbol, _decimals);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}