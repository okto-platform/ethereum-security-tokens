pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";

contract Whitelist is Ownable {
    using AddressArrayLib for address[];

    struct Property {
        bytes32 code;
        bytes32 bucket;
        uint8 from;
        uint16 len;
    }

    address[] public validators;
    mapping(address => mapping (bytes32 => bytes32)) properties;
    mapping(bytes32 => Property) propertiesDefinition;

    modifier onlyValidator {
        require(validators.contains(msg.sender), "Only validators can do this");
        _;
    }

    constructor(address[] _validators, bytes32[] codes, bytes32[] buckets, uint8[] froms, uint16[] lens)
    public
    {
        require(codes.length == buckets.length, "Different number of properties and buckets");
        require(codes.length == froms.length, "Different number of properties and indexes");
        require(codes.length == lens.length, "Different number of properties and lengths");

        validators = _validators;

        for (uint i = 0; i < codes.length; i++) {
            propertiesDefinition[codes[i]].code = codes[i];
            propertiesDefinition[codes[i]].bucket = buckets[i];
            propertiesDefinition[codes[i]].from = froms[i];
            propertiesDefinition[codes[i]].len = lens[i];
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

    function setBucket(address investor, bytes32 bucket, bytes32 value)
    onlyValidator
    public
    {
        properties[investor][bucket] = value;

        emit UpdatedInvestor(investor, bucket, value);
    }

    function setManyBuckets(address[] investors, bytes32[] buckets, bytes32[] values)
    onlyValidator
    public
    {
        require(investors.length == buckets.length, "Number of investors and number of buckets does not match");
        require(investors.length == values.length, "Number of investors and number of values does not match");

        for (uint i = 0; i < investors.length; i++) {
            properties[investors[i]][buckets[i]] = values[i];

            emit UpdatedInvestor(investors[i], buckets[i], values[i]);
        }
    }

    function getBucket(address investor, bytes32 bucket)
    public view returns(bytes32)
    {
        return properties[investor][bucket];
    }

    function getProperty(address investor, bytes32 property)
    public view returns(bytes32)
    {
        Property storage propertyDefinition = propertiesDefinition[property];
        require(propertyDefinition.code != bytes32(0), "Property not defined");

        if (propertyDefinition.from == 0 && propertyDefinition.len == 256) {
            // no need to manipulates bits as the property uses the whole bucket
            return properties[investor][propertyDefinition.bucket];
        }

        uint256 value = uint256(properties[investor][propertyDefinition.bucket]);
        value <<= propertyDefinition.from;
        value >>= 256 - propertyDefinition.len;
        return bytes32(value);
    }

    function addProperty(bytes32 code, bytes32 bucket, uint8 from, uint16 len)
    onlyOwner
    public
    {
        require(propertiesDefinition[code].code == bytes32(0), "Property already defined");

        propertiesDefinition[code].code = code;
        propertiesDefinition[code].code = bucket;
        propertiesDefinition[code].from = from;
        propertiesDefinition[code].len = len;

        emit AddedProperty(code, bucket, from, len);
    }

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
    event AddedProperty(bytes32 code, bytes32 bucket, uint8 from, uint16 len);
    event UpdatedInvestor(address investor, bytes32 bucket, bytes32 value);
}

contract WhitelistFactory is Factory {
    function createInstance(address[] validators, bytes32[] codes, bytes32[] buckets, uint8[] froms, uint16[] lens)
    public returns(address)
    {
        Whitelist instance = new Whitelist(validators, codes, buckets, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}