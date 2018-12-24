pragma solidity ^0.5.0;

import "../utils/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";
import "./WhitelistModule.sol";
import "../tokens/SecurityToken.sol";

contract Whitelist is Ownable {
    using AddressArrayLib for address[];

    struct Property {
        bytes32 code;
        bytes32 bucket;
        uint8 from;
        uint16 len;
    }

    address public tokenAddress;
    address[] public validators;
    mapping(address => mapping (bytes32 => bytes32)) properties;
    mapping(bytes32 => Property) propertiesDefinition;
    address[] internal modules;

    modifier onlyValidator {
        require(validators.contains(msg.sender), "Only validators can do this");
        _;
    }

    modifier onlyOwnerTx() {
        require(msg.sender == owner || tx.origin == owner);
        _;
    }

    modifier isDraft() {
        SecurityToken token = SecurityToken(tokenAddress);
        require(!token.released(), "Token is already released");
        _;
    }

    constructor(address _tokenAddress, address[] memory _validators, bytes32[] memory codes, bytes32[] memory buckets, uint8[] memory froms, uint16[] memory lens)
    public
    {
        require(_tokenAddress != address(0), "Token address is required");
        require(codes.length == buckets.length, "Different number of properties and buckets");
        require(codes.length == froms.length, "Different number of properties and indexes");
        require(codes.length == lens.length, "Different number of properties and lengths");

        tokenAddress = _tokenAddress;
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
        bytes32 oldValue = properties[investor][bucket];
        properties[investor][bucket] = value;

        notifyInvestorUpdated(investor, bucket, value, oldValue);
    }

    function setManyBuckets(address[] memory investors, bytes32[] memory buckets, bytes32[] memory values)
    onlyValidator
    public
    {
        require(investors.length == buckets.length, "Number of investors and number of buckets does not match");
        require(investors.length == values.length, "Number of investors and number of values does not match");

        bytes32 oldValue;
        for (uint i = 0; i < investors.length; i++) {
            oldValue = properties[investors[i]][buckets[i]];
            properties[investors[i]][buckets[i]] = values[i];

            notifyInvestorUpdated(investors[i], buckets[i], values[i], oldValue);
        }
    }

    function notifyInvestorUpdated(address investor, bytes32 bucket, bytes32 newValue, bytes32 oldValue)
    internal
    {
        WhitelistModule module;
        for (uint i = 0; i < modules.length; i++) {
            module = WhitelistModule(modules[i]);
            module.investorUpdated(investor, bucket, newValue, oldValue);
        }

        emit UpdatedInvestor(investor, bucket, newValue);
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

    function addModule(address moduleAddress)
    onlyOwnerTx isDraft
    public
    {
        require(moduleAddress != address(0), "Module address is required");

        modules.addIfNotPresent(moduleAddress);

        WhitelistModule module = WhitelistModule(moduleAddress);

        emit AddedModule(moduleAddress, module.moduleType());
    }

    function removeModule(address moduleAddress)
    onlyOwnerTx isDraft
    public
    {
        modules.removeValue(moduleAddress);

        emit RemovedModule(moduleAddress);
    }

    function isModule(address moduleAddress)
    public view returns (bool)
    {
        return modules.contains(moduleAddress);
    }

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
    event AddedProperty(bytes32 code, bytes32 bucket, uint8 from, uint16 len);
    event AddedModule(address moduleAddress, string moduleType);
    event RemovedModule(address moduleAddress);
    event UpdatedInvestor(address investor, bytes32 bucket, bytes32 value);
}

contract WhitelistFactory is Factory {
    function createInstance(address tokenAddress, address[] memory validators, bytes32[] memory codes, bytes32[] memory buckets, uint8[] memory froms, uint16[] memory lens)
    public returns(address)
    {
        Whitelist instance = new Whitelist(tokenAddress, validators, codes, buckets, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        return address(instance);
    }
}
