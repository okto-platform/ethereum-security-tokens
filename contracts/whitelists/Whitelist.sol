pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";
import "../utils/Bits.sol";

contract Whitelist is Ownable {
    using AddressArrayLib for address[];
    using Bits for uint256;

    struct Property {
        byte code;
        uint8 from;
        uint8 len;
        string name;
    }

    address[] public validators;
    mapping(address => uint256) properties;
    mapping(byte => Property) propertiesDefinition;


    modifier onlyValidator {
        require(validators.contains(msg.sender), "Only validators can do this");
        _;
    }

    constructor(address[] _validators, byte[] props, string[] names, uint8[] froms, uint8[] lens)
    public
    {
        require(props.length == names.length, "Different number of properties and names");
        require(props.length == froms.length, "Different number of properties and indexes");
        require(props.length == lens.length, "Different number of properties and lengths");

        validators = _validators;

        for (uint i = 0; i < props.length; i++) {
            propertiesDefinition[props[i]].code = props[i];
            propertiesDefinition[props[i]].from = froms[i];
            propertiesDefinition[props[i]].len = lens[i];
            propertiesDefinition[props[i]].name = names[i];
        }
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

    function setProps(address investor, uint256 props)
    onlyValidator
    public
    {
        properties[investor] = props;
    }

    function getProps(address investor)
    public view returns(uint256)
    {
        return properties[investor];
    }

    function getProp(address investor, byte prop)
    public view returns(uint256)
    {
        require(propertiesDefinition[prop].code != 0, "Property not defined");

        return properties[investor].bits(propertiesDefinition[prop].from, propertiesDefinition[prop].len);
    }

    function addProperty(byte prop, string name, uint8 from, uint8 len)
    onlyOwner
    {
        require(propertiesDefinition[prop].code == 0, "Property already defined");

        propertiesDefinition[prop].code = prop;
        propertiesDefinition[prop].from = from;
        propertiesDefinition[prop].len = len;
        propertiesDefinition[prop].name = name;

        emit AddedProperty(prop, name, from, len);
    }

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
    event AddedProperty(byte prop, string name, uint8 from, uint8 len);
}

contract WhitelistFactory is Factory {
    function createInstance(address[] validators, byte[] props, string[] names, uint8[] froms, uint8[] lens)
    public returns(address)
    {
        Whitelist instance = new Whitelist(validators, props, names, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}