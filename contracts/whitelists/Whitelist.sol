pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";

contract Whitelist is Ownable {
    using AddressArrayLib for address[];

    struct Property {
        bytes32 code;
        uint8 from;
        uint8 len;
    }

    address[] public validators;
    mapping(address => uint256) properties;
    mapping(bytes32 => Property) propertiesDefinition;


    modifier onlyValidator {
        require(validators.contains(msg.sender), "Only validators can do this");
        _;
    }

    constructor(address[] _validators, bytes32[] props, uint8[] froms, uint8[] lens)
    public
    {
        require(props.length == froms.length, "Different number of properties and indexes");
        require(props.length == lens.length, "Different number of properties and lengths");

        validators = _validators;

        for (uint i = 0; i < props.length; i++) {
            propertiesDefinition[props[i]].code = props[i];
            propertiesDefinition[props[i]].from = froms[i];
            propertiesDefinition[props[i]].len = lens[i];
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

        emit UpdatedInvestor(investor, props);
    }

    function setManyProps(address[] investors, uint256[] props)
    onlyValidator
    public
    {
        require(investors.length == props.length, "Number of investors and number of props does not match");

        for (uint i = 0; i < investors.length; i++) {
            properties[investors[i]] = props[i];

            emit UpdatedInvestor(investors[i], props[i]);
        }
    }

    function getProps(address investor)
    public view returns(uint256)
    {
        return properties[investor];
    }

    function getProp(address investor, bytes32 prop)
    public view returns(uint256)
    {
        require(propertiesDefinition[prop].code != bytes32(0), "Property not defined");

        uint256 props = properties[investor];
        props <<= propertiesDefinition[prop].from;
        props >>= 256 - propertiesDefinition[prop].len;
        return props;
    }

    function addProperty(bytes32 prop, uint8 from, uint8 len)
    onlyOwner
    public
    {
        require(propertiesDefinition[prop].code == bytes32(0), "Property already defined");

        propertiesDefinition[prop].code = prop;
        propertiesDefinition[prop].from = from;
        propertiesDefinition[prop].len = len;

        emit AddedProperty(prop, from, len);
    }

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
    event AddedProperty(bytes32 prop, uint8 from, uint8 len);
    event UpdatedInvestor(address investor, bytes32 props);
}

contract WhitelistFactory is Factory {
    function createInstance(address[] validators, bytes32[] props, uint8[] froms, uint8[] lens)
    public returns(address)
    {
        Whitelist instance = new Whitelist(validators, props, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}