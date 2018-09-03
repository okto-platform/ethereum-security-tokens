pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Whitelist is Ownable {
    enum PropertyType {Undefined, String, Number, Boolean}

    mapping(address => mapping(string => string)) stringProperties;
    mapping(address => mapping(string => uint)) uintProperties;
    mapping(address => mapping(string => bool)) boolProperties;

    function setStringProperty(address _investor, string _property, string _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.String), "Property is not valid or not a string");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        stringProperties[_investor][_property] = _value;
    }

    function setBooleanProperty(address _investor, string _property, bool _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.Boolean), "Property is not valid or not boolean");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        boolProperties[_investor][_property] = _value;
    }

    function setNumberProperty(address _investor, string _property, uint _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.Number), "Property is not valid or not a number");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        uintProperties[_investor][_property] = _value;
    }

    function checkPropertyTrue(address _investor, string _property)
    public returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Boolean));

        bool propValue = boolProperties[_investor][_property];
        if (propValue) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyFalse(address _investor, string _property)
    public returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Boolean));

        bool propValue = boolProperties[_investor][_property];
        if (propValue) {
            return false;
        } else {
            return true;
        }
    }

    function checkPropertyEquals(address investor, string property, string value)
    public returns(bool)
    {

    }

    function checkPropertyNotEquals(address investor, string property, string value)
    public returns(bool)
    {

    }

    function checkPropertyEquals(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function checkPropertyNotEquals(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function checkPropertyGreater(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function checkPropertyGreaterOrEquals(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function checkPropertyLess(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function checkPropertyLessOrEquals(address investor, string property, uint256 value)
    public returns(bool)
    {

    }

    function isValidValueForProperty(string _property, string _value)
    public returns(bool);

    function isValidValueForProperty(string _property, bool _value)
    public returns(bool);

    function isValidValueForProperty(string _property, uint _value)
    public returns(bool);

    function checkPropertyType(string _property, PropertyType _type)
    public returns(bool);
}