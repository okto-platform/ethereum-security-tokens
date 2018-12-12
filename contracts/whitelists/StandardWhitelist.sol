pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "./Whitelist.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Standard properties codes:
//
// KYC flag                           index   0, length   1 bits
// KYC expiration timestamp           index   1, length  40 bits
// Country code (two letters code)    index  41, length  16 bits
// Accredited investor                index  57, length   1 bits
// Insider                            index  58, length   1 bits
// Lockup expiration                  index  59, length  40 bits
// Investor ID                        index  99, length  24 bits
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract StandardWhitelist is Whitelist {
    constructor(address[] validators, bytes32[] props, uint8[] froms, uint8[] lens)
    Whitelist(validators, props, froms, lens)
    public
    {
        // define this standard properties; if they were also passed in the constructor
        // they will be overridden

        bytes32 kyc = bytes32("kyc");
        propertiesDefinition[kyc].code = kyc;
        propertiesDefinition[kyc].from = 0;
        propertiesDefinition[kyc].len = 1;

        bytes32 kycExpiration = bytes32("kycExpiration");
        propertiesDefinition[kycExpiration].code = kycExpiration;
        propertiesDefinition[kycExpiration].from = 1;
        propertiesDefinition[kycExpiration].len = 40;

        bytes32 country = bytes32("country");
        propertiesDefinition[country].code = country;
        propertiesDefinition[country].from = 41;
        propertiesDefinition[country].len = 16;

        bytes32 accredited = bytes32("accredited");
        propertiesDefinition[accredited].code = accredited;
        propertiesDefinition[accredited].from = 57;
        propertiesDefinition[accredited].len = 1;

        bytes32 insider = bytes32("insider");
        propertiesDefinition[insider].code = insider;
        propertiesDefinition[insider].from = 58;
        propertiesDefinition[insider].len = 1;

        bytes32 lockupExpiration = bytes32("lockupExpiration");
        propertiesDefinition[lockupExpiration].code = lockupExpiration;
        propertiesDefinition[lockupExpiration].from = 59;
        propertiesDefinition[lockupExpiration].len = 40;

        bytes32 investorId = bytes32("investorId");
        propertiesDefinition[lockupExpiration].code = investorId;
        propertiesDefinition[lockupExpiration].from = 99;
        propertiesDefinition[lockupExpiration].len = 24;
    }
}

contract StandardWhitelistFactory is Factory {
    function createInstance(address[] validators, bytes32[] props, uint8[] froms, uint8[] lens)
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist(validators, props, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}