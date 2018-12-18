pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Factory.sol";
import "./Whitelist.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Standard properties:
//
// General Bucket ----------------------------------------------
// KYC flag                           index   0, length   1 bits
// KYC expiration timestamp           index   1, length  40 bits
// Accredited investor                index  41, length   1 bits
// Accredited expiration timestamp    index  42, length  40 bits
// Country code (two letters code)    index  82, length  16 bits
// Insider                            index  98, length   1 bits
// Lockup expiration                  index  99, length  40 bits
// Investor ID Bucket ------------------------------------------
// Investor ID                        index   0, length 256 bits
// KYC Reference Bucket ----------------------------------------
// KYC Reference                      index   0, length 256 bits
// Accredited Reference Bucket ---------------------------------
// Accredited Reference               index   0, length 256 bits
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract StandardWhitelist is Whitelist {
    constructor(address[] validators, bytes32[] codes, bytes32[] buckets, uint8[] froms, uint16[] lens)
    Whitelist(validators, codes, buckets, froms, lens)
    public
    {
        // define this standard properties; if they were also passed in the constructor
        // they will be overridden

        bytes32 kyc = bytes32("kyc");
        propertiesDefinition[kyc].code = kyc;
        propertiesDefinition[kyc].bucket = bytes32("general");
        propertiesDefinition[kyc].from = 0;
        propertiesDefinition[kyc].len = 1;

        bytes32 kycExpiration = bytes32("kycExpiration");
        propertiesDefinition[kycExpiration].code = kycExpiration;
        propertiesDefinition[kycExpiration].bucket = bytes32("general");
        propertiesDefinition[kycExpiration].from = 1;
        propertiesDefinition[kycExpiration].len = 40;

        bytes32 accredited = bytes32("accredited");
        propertiesDefinition[accredited].code = accredited;
        propertiesDefinition[accredited].bucket = bytes32("general");
        propertiesDefinition[accredited].from = 41;
        propertiesDefinition[accredited].len = 1;

        bytes32 accreditedExpiration = bytes32("accreditedExpiration");
        propertiesDefinition[accreditedExpiration].code = accreditedExpiration;
        propertiesDefinition[accreditedExpiration].bucket = bytes32("general");
        propertiesDefinition[accreditedExpiration].from = 42;
        propertiesDefinition[accreditedExpiration].len = 40;

        bytes32 country = bytes32("country");
        propertiesDefinition[country].code = country;
        propertiesDefinition[country].bucket = bytes32("general");
        propertiesDefinition[country].from = 82;
        propertiesDefinition[country].len = 16;

        bytes32 insider = bytes32("insider");
        propertiesDefinition[insider].code = insider;
        propertiesDefinition[insider].bucket = bytes32("general");
        propertiesDefinition[insider].from = 98;
        propertiesDefinition[insider].len = 1;

        bytes32 lockupExpiration = bytes32("lockupExpiration");
        propertiesDefinition[lockupExpiration].code = lockupExpiration;
        propertiesDefinition[lockupExpiration].bucket = bytes32("general");
        propertiesDefinition[lockupExpiration].from = 99;
        propertiesDefinition[lockupExpiration].len = 40;

        bytes32 investorId = bytes32("investorId");
        propertiesDefinition[investorId].code = investorId;
        propertiesDefinition[investorId].bucket = bytes32("investorId");
        propertiesDefinition[investorId].from = 0;
        propertiesDefinition[investorId].len = 256;

        bytes32 kycReference = bytes32("kycReference");
        propertiesDefinition[kycReference].code = kycReference;
        propertiesDefinition[kycReference].bucket = bytes32("kycReference");
        propertiesDefinition[kycReference].from = 0;
        propertiesDefinition[kycReference].len = 256;

        bytes32 accreditedReference = bytes32("accreditedReference");
        propertiesDefinition[accreditedReference].code = accreditedReference;
        propertiesDefinition[accreditedReference].bucket = bytes32("accreditedReference");
        propertiesDefinition[accreditedReference].from = 0;
        propertiesDefinition[accreditedReference].len = 256;
    }
}

contract StandardWhitelistFactory is Factory {
    function createInstance(address[] validators, bytes32[] codes, bytes32[] buckets, uint8[] froms, uint16[] lens)
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist(validators, codes, buckets, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        return instance;
    }
}