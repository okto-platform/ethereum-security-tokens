pragma solidity ^0.5.0;

import "../utils/Ownable.sol";
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
// ATS                                index 139, length   1 bits
// Investor ID Bucket ------------------------------------------
// Investor ID                        index   0, length 256 bits
// KYC Reference Bucket ----------------------------------------
// KYC Reference                      index   0, length 256 bits
// Accredited Reference Bucket ---------------------------------
// Accredited Reference               index   0, length 256 bits
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract StandardWhitelist is Whitelist {
    constructor(address tokenAddress, address[] memory validators, bytes32[] memory codes, bytes32[] memory buckets, uint8[] memory froms, uint16[] memory lens)
    Whitelist(tokenAddress, validators, codes, buckets, froms, lens)
    public
    {
        // define this standard properties; if they were also passed in the constructor
        // they will be overridden

        propertiesDefinition[bytes32("kyc")].code = bytes32("kyc");
        propertiesDefinition[bytes32("kyc")].bucket = bytes32("general");
        propertiesDefinition[bytes32("kyc")].from = 0;
        propertiesDefinition[bytes32("kyc")].len = 1;

        propertiesDefinition[bytes32("kycExpiration")].code = bytes32("kycExpiration");
        propertiesDefinition[bytes32("kycExpiration")].bucket = bytes32("general");
        propertiesDefinition[bytes32("kycExpiration")].from = 1;
        propertiesDefinition[bytes32("kycExpiration")].len = 40;

        propertiesDefinition[bytes32("accredited")].code = bytes32("accredited");
        propertiesDefinition[bytes32("accredited")].bucket = bytes32("general");
        propertiesDefinition[bytes32("accredited")].from = 41;
        propertiesDefinition[bytes32("accredited")].len = 1;

        propertiesDefinition[bytes32("accreditedExpiration")].code = bytes32("accreditedExpiration");
        propertiesDefinition[bytes32("accreditedExpiration")].bucket = bytes32("general");
        propertiesDefinition[bytes32("accreditedExpiration")].from = 42;
        propertiesDefinition[bytes32("accreditedExpiration")].len = 40;

        propertiesDefinition[bytes32("country")].code = bytes32("country");
        propertiesDefinition[bytes32("country")].bucket = bytes32("general");
        propertiesDefinition[bytes32("country")].from = 82;
        propertiesDefinition[bytes32("country")].len = 16;

        propertiesDefinition[bytes32("insider")].code = bytes32("insider");
        propertiesDefinition[bytes32("insider")].bucket = bytes32("general");
        propertiesDefinition[bytes32("insider")].from = 98;
        propertiesDefinition[bytes32("insider")].len = 1;

        propertiesDefinition[bytes32("lockupExpiration")].code = bytes32("lockupExpiration");
        propertiesDefinition[bytes32("lockupExpiration")].bucket = bytes32("general");
        propertiesDefinition[bytes32("lockupExpiration")].from = 99;
        propertiesDefinition[bytes32("lockupExpiration")].len = 40;

        propertiesDefinition[bytes32("ats")].code = bytes32("ats");
        propertiesDefinition[bytes32("ats")].bucket = bytes32("general");
        propertiesDefinition[bytes32("ats")].from = 139;
        propertiesDefinition[bytes32("ats")].len = 1;

        propertiesDefinition[bytes32("investorId")].code = bytes32("investorId");
        propertiesDefinition[bytes32("investorId")].bucket = bytes32("investorId");
        propertiesDefinition[bytes32("investorId")].from = 0;
        propertiesDefinition[bytes32("investorId")].len = 256;

        propertiesDefinition[bytes32("kycReference")].code = bytes32("kycReference");
        propertiesDefinition[bytes32("kycReference")].bucket = bytes32("kycReference");
        propertiesDefinition[bytes32("kycReference")].from = 0;
        propertiesDefinition[bytes32("kycReference")].len = 256;

        propertiesDefinition[bytes32("accreditedReference")].code = bytes32("accreditedReference");
        propertiesDefinition[bytes32("accreditedReference")].bucket = bytes32("accreditedReference");
        propertiesDefinition[bytes32("accreditedReference")].from = 0;
        propertiesDefinition[bytes32("accreditedReference")].len = 256;
    }
}

contract StandardWhitelistFactory is Factory {
    function createInstance(address tokenAddress, address[] memory validators, bytes32[] memory codes, bytes32[] memory buckets, uint8[] memory froms, uint16[] memory lens)
    public returns(address)
    {
        StandardWhitelist instance = new StandardWhitelist(tokenAddress, validators, codes, buckets, froms, lens);
        instance.transferOwnership(msg.sender);
        addInstance(address(instance));
        return address(instance);
    }
}
