pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "./TypedWhitelist.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Standard properties codes:
//
// 0x01 - bool - KYC flag
// 0x02 - string - Country code (two letters lower case)
// 0x03 - uint - Expiration timestamp
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract StandardWhitelist is TypedWhitelist {
    constructor(address[] validators, byte[] props, TypedWhitelist.PropertyType[] types)
    TypedWhitelist(validators, props, types)
    public
    {
        // define this standard properties; if they were also passed in the constructor
        // they will be overridden
        propertiesType[0x01] = TypedWhitelist.PropertyType.Boolean;
        propertiesType[0x02] = TypedWhitelist.PropertyType.String;
        propertiesType[0x03] = TypedWhitelist.PropertyType.Number;
    }
}

contract StandardWhitelistFactory is Factory {
    function createInstance(address[] validators, byte[] props, TypedWhitelist.PropertyType[] types)
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist(validators, props, types);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}