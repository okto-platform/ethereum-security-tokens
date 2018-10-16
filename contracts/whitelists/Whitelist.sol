pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Whitelist is Ownable {
    enum PropertyType {Undefined, String, Number, Boolean}

    mapping(address => mapping(string => string)) stringProperties;
    mapping(address => mapping(string => uint)) uintProperties;
    mapping(address => mapping(string => bool)) boolProperties;

    function setProperty(address _investor, string _property, string _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.String), "Property is not valid or not a string");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        stringProperties[_investor][_property] = _value;
    }

    function setProperty(address _investor, string _property, bool _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.Boolean), "Property is not valid or not boolean");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        boolProperties[_investor][_property] = _value;
    }

    function setProperty(address _investor, string _property, uint _value)
    public onlyOwner
    {
        require(checkPropertyType(_property, PropertyType.Number), "Property is not valid or not a number");
        require(isValidValueForProperty(_property, _value), "Value is not valid for this property");

        uintProperties[_investor][_property] = _value;
    }

    function checkPropertyTrue(address _investor, string _property)
    public view returns(bool)
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
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Boolean));

        bool propValue = boolProperties[_investor][_property];
        if (propValue) {
            return false;
        } else {
            return true;
        }
    }

    function checkPropertyEquals(address _investor, string _property, string _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.String));

        string memory propValue = stringProperties[_investor][_property];
        if (keccak256(bytes(propValue)) == keccak256(bytes(_value))) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyNotEquals(address _investor, string _property, string _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.String));

        string memory propValue = stringProperties[_investor][_property];
        if (keccak256(bytes(propValue)) == keccak256(bytes(_value))) {
            return false;
        } else {
            return true;
        }
    }

    function checkPropertyEquals(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue == _value) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyNotEquals(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue == _value) {
            return false;
        } else {
            return true;
        }
    }

    function checkPropertyGreater(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue > _value) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyGreaterOrEquals(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue >= _value) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyLess(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue < _value) {
            return true;
        } else {
            return false;
        }
    }

    function checkPropertyLessOrEquals(address _investor, string _property, uint256 _value)
    public view returns(bool)
    {
        require(checkPropertyType(_property, PropertyType.Number));

        uint propValue = uintProperties[_investor][_property];
        if (propValue <= _value) {
            return true;
        } else {
            return false;
        }
    }

    function isValidValueForProperty(string _property, string _value)
    public view returns(bool);

    function isValidValueForProperty(string _property, bool _value)
    public view returns(bool);

    function isValidValueForProperty(string _property, uint _value)
    public view returns(bool);

    function checkPropertyType(string _property, PropertyType _type)
    public view returns(bool);
}