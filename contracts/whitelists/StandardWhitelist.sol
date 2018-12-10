pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "./Whitelist.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Standard properties codes:
//
// 0x01 KYC flag                           index   0, length   1 bits
// 0x02 KYC expiration timestamp           index   1, length  40 bits
// 0x03 Country code (two letters code)    index  41, length  16 bits
// 0x04 Accredited investor                index  57, length   1 bits
// 0x05 Insider                            index  58, length   1 bits
// 0x06 Lockup expiration                  index  59, length  40 bits
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract StandardWhitelist is Whitelist {
    constructor(address[] validators, bytes32[] props, uint8[] froms, uint8[] lens)
    Whitelist(validators, props, names, froms, lens)
    public
    {
        // define this standard properties; if they were also passed in the constructor
        // they will be overridden

        propertiesDefinition[0x01].code = 0x01;
        propertiesDefinition[0x01].name = 'kyc';
        propertiesDefinition[0x01].from = 0;
        propertiesDefinition[0x01].len = 1;

        propertiesDefinition[0x02].code = 0x02;
        propertiesDefinition[0x02].name = 'kycExpiration';
        propertiesDefinition[0x02].from = 1;
        propertiesDefinition[0x02].len = 40;

        propertiesDefinition[0x03].code = 0x03;
        propertiesDefinition[0x03].name = 'country';
        propertiesDefinition[0x03].from = 41;
        propertiesDefinition[0x03].len = 16;

        propertiesDefinition[0x04].code = 0x04;
        propertiesDefinition[0x04].name = 'accredited';
        propertiesDefinition[0x04].from = 57;
        propertiesDefinition[0x04].len = 1;

        propertiesDefinition[0x05].code = 0x05;
        propertiesDefinition[0x05].name = 'insider';
        propertiesDefinition[0x05].from = 58;
        propertiesDefinition[0x05].len = 1;

        propertiesDefinition[0x06].code = 0x06;
        propertiesDefinition[0x06].name = 'lockupExpiration';
        propertiesDefinition[0x06].from = 59;
        propertiesDefinition[0x06].len = 40;
    }
}

contract StandardWhitelistFactory is Factory {
    function createInstance(address[] validators, byte[] props, string[] names, uint8[] froms, uint8[] lens)
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist(validators, props, names, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}