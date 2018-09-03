pragma solidity ^0.4.24;

import "./Whitelist.sol";

contract StandardWhitelist is Whitelist {
    mapping (string => PropertyType) propertiesType;

    constructor() {
        propertiesType["kyc"] = PropertyType.Boolean;
        propertiesType["expiration"] = PropertyType.Number;
        propertiesType["country"] = PropertyType.String;
    }

    function isValidValueForProperty(string _property, string _value)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.String);
    }


    function isValidValueForProperty(string _property, bool _value)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.Boolean);
    }

    function isValidValueForProperty(string _property, uint _value)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.Number);
    }

    function checkPropertyType(string _property, PropertyType _type)
    public returns(bool)
    {
        PropertyType propertyType = propertiesType[_property];
        return propertyType == _type;
    }
}

contract StandardWhitelistFactory {
    mapping(string => address) instances;

    event InstanceCreated(address contractAddress, string name, address sender);

    function createInstance(string _name)
    public returns(address)
    {
        require(instances[_name] == address(0), "Name is already taken");
        StandardWhitelist instance = new StandardWhitelist();
        instance.transferOwnership(msg.sender);
        instances[_name] = instance;
        emit InstanceCreated(instance, _name, msg.sender);
        return instance;
    }

    function getInstance(string _name)
    public view returns(address)
    {
        return instances[_name];
    }
}