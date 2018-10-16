pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";

contract Whitelist is Ownable {
    using AddressArrayLib for address[];

    address[] public validators;
    mapping(address => mapping(byte => string)) stringProperties;
    mapping(address => mapping(byte => uint)) uintProperties;
    mapping(address => mapping(byte => bool)) boolProperties;

    modifier onlyValidator {
        require(validators.contains(msg.sender), "Only validators can do this");
        _;
    }

    constructor(address[] _validators)
    public
    {
        validators = _validators;
    }

    function addValidator(address validator)
    onlyOwner
    public
    {
        require(validator != address(0), "Invalid validator address");

        validators.addIfNotPresent(validator);

        emit AddedValidator(validator);
    }

    function removeValidator(address validator)
    onlyOwner
    public
    {
        require(validator != address(0), "Invalid validator address");

        validators.removeValue(validator);

        emit RemovedValidator(validator);
    }

    function isValidator(address validator)
    public view returns(bool)
    {
        return validators.contains(validator);
    }

    function setString(address investor, byte prop, string value)
    onlyValidator
    public
    {
        stringProperties[investor][prop] = value;
    }

    function setBool(address investor, byte prop, bool value)
    onlyValidator
    public
    {
        boolProperties[investor][prop] = value;
    }

    function setNumber(address investor, byte prop, uint value)
    onlyValidator
    public
    {
        uintProperties[investor][prop] = value;
    }

    function getString(address investor, byte prop)
    public view returns(string)
    {
        return stringProperties[investor][prop];
    }

    function getBool(address investor, byte prop)
    public view returns(bool)
    {
        return boolProperties[investor][prop];
    }

    function getNumber(address investor, byte prop)
    public view returns(uint)
    {
        return uintProperties[investor][prop];
    }

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
}

contract WhitelistFactory is Factory {
    function createInstance(address[] validators)
    public returns(address)
    {
        Whitelist instance = new Whitelist(validators);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}