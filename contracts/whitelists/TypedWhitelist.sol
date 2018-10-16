pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "./Whitelist.sol";

contract TypedWhitelist is Whitelist {
    enum PropertyType {Undefined, String, Number, Boolean}

    mapping (byte => PropertyType) propertiesType;

    constructor(address[] validators, byte[] props, PropertyType[] types)
    Whitelist(validators)
    public
    {
        require(props.length == types.length, "Different number of properties and types");

        for (uint i = 0; i < props.length; i++) {
            propertiesType[props[i]] = types[i];
        }
    }

    function addProperty(byte prop, PropertyType propType)
    onlyOwner
    public
    {
        require(propertiesType[prop] == PropertyType.Undefined, "Property already defined");

        propertiesType[prop] = propType;

        emit AddedProperty(prop, propType);
    }

    function setString(address investor, byte prop, string value)
    public
    {
        require(checkPropertyType(prop, PropertyType.String), "Property is not valid or not a string");
        require(isValidValueForProperty(prop, value), "Value is not valid for this property");

        Whitelist.setString(investor, prop, value);
    }

    function setBool(address investor, byte prop, bool value)
    public
    {
        require(checkPropertyType(prop, PropertyType.Boolean), "Property is not valid or not boolean");
        require(isValidValueForProperty(prop, value), "Value is not valid for this property");

        Whitelist.setBool(investor, prop, value);
    }

    function setNumber(address investor, byte prop, uint value)
    public
    {
        require(checkPropertyType(prop, PropertyType.Number), "Property is not valid or not a number");
        require(isValidValueForProperty(prop, value), "Value is not valid for this property");

        Whitelist.setNumber(investor, prop, value);
    }

    function getString(address investor, byte prop)
    public view returns(string)
    {
        require(checkPropertyType(prop, PropertyType.String));

        return Whitelist.getString(investor, prop);
    }

    function getBool(address investor, byte prop)
    public view returns(bool)
    {
        require(checkPropertyType(prop, PropertyType.Boolean));

        return Whitelist.getBool(investor, prop);
    }

    function getNumber(address investor, byte prop)
    public view returns(uint)
    {
        require(checkPropertyType(prop, PropertyType.Number));

        return Whitelist.getNumber(investor, prop);
    }

    function isValidValueForProperty(byte prop, string)
    public view returns(bool)
    {
        return checkPropertyType(prop, PropertyType.String);
    }


    function isValidValueForProperty(byte prop, bool)
    public view returns(bool)
    {
        return checkPropertyType(prop, PropertyType.Boolean);
    }

    function isValidValueForProperty(byte prop, uint)
    public view returns(bool)
    {
        return checkPropertyType(prop, PropertyType.Number);
    }

    function checkPropertyType(byte prop, PropertyType propType)
    public view returns(bool)
    {
        PropertyType propertyType = propertiesType[prop];
        return propertyType == propType;
    }

    event AddedProperty(byte prop, PropertyType propType);
}

contract TypedWhitelistFactory is Factory {
    function createInstance(address[] validators, byte[] props, TypedWhitelist.PropertyType[] types)
    public returns(address)
    {
        TypedWhitelist instance = new TypedWhitelist(validators, props, types);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}