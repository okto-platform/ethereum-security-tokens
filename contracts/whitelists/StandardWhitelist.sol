pragma solidity ^0.4.24;

import "./Whitelist.sol";
import "../utils/Factory.sol";

contract StandardWhitelist is Whitelist {
    mapping (string => PropertyType) propertiesType;

    constructor()
    public
    {
        propertiesType["kyc"] = PropertyType.Boolean;
        propertiesType["expiration"] = PropertyType.Number;
        propertiesType["country"] = PropertyType.String;
    }

    function isValidValueForProperty(string _property, string)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.String);
    }


    function isValidValueForProperty(string _property, bool)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.Boolean);
    }

    function isValidValueForProperty(string _property, uint)
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

contract StandardWhitelistFactory is Factory {
    function createInstance()
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist();
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}