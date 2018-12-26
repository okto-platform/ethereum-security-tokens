pragma solidity ^0.5.0;

import "../utils/Ownable.sol";
import "../utils/Factory.sol";
import "./Whitelist.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
// Standard properties:
//
// General Bucket ----------------------------------------------
// KYC status                         index   0, length   2 bits (00: pending, 01: auto-approved, 10: manually-approved, 11: disapproved)
// KYC status updated                 index   2, length  40 bits
// AML status                         index  42, length   2 bits (00: pending, 01: auto-approved, 10: manually-approved, 11: disapproved)
// AML status updated                 index  44, length  40 bits
// Accredited status                  index  84, length   3 bits (000: pending, 001: auto-approved, 010: manually-approved, 011: self-approved, 100: disapproved)
// Accredited status updated          index  87, length  40 bits
// Country code (two letters code)    index 127, length  16 bits (two letters ascii code lower case)
// Insider                            index 143, length   1 bits
// Lockup expiration                  index 144, length  40 bits
// ATS                                index 184, length   1 bits
// Investor ID Bucket ------------------------------------------
// Investor ID                        index   0, length 256 bits
// KYC Reference Bucket ----------------------------------------
// KYC Reference                      index   0, length 256 bits
// AML Reference Bucket ----------------------------------------
// AML Reference                      index   0, length 256 bits
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

        propertiesDefinition[bytes32("kycStatus")].code = bytes32("kycStatus");
        propertiesDefinition[bytes32("kycStatus")].bucket = bytes32("general");
        propertiesDefinition[bytes32("kycStatus")].from = 0;
        propertiesDefinition[bytes32("kycStatus")].len = 2;

        propertiesDefinition[bytes32("kycStatusUpdated")].code = bytes32("kycStatusUpdated");
        propertiesDefinition[bytes32("kycStatusUpdated")].bucket = bytes32("general");
        propertiesDefinition[bytes32("kycStatusUpdated")].from = 2;
        propertiesDefinition[bytes32("kycStatusUpdated")].len = 40;

        propertiesDefinition[bytes32("amlStatus")].code = bytes32("amlStatus");
        propertiesDefinition[bytes32("amlStatus")].bucket = bytes32("general");
        propertiesDefinition[bytes32("amlStatus")].from = 42;
        propertiesDefinition[bytes32("amlStatus")].len = 2;

        propertiesDefinition[bytes32("amlStatusUpdated")].code = bytes32("amlStatusUpdated");
        propertiesDefinition[bytes32("amlStatusUpdated")].bucket = bytes32("general");
        propertiesDefinition[bytes32("amlStatusUpdated")].from = 44;
        propertiesDefinition[bytes32("amlStatusUpdated")].len = 40;

        propertiesDefinition[bytes32("accreditedStatus")].code = bytes32("accreditedStatus");
        propertiesDefinition[bytes32("accreditedStatus")].bucket = bytes32("general");
        propertiesDefinition[bytes32("accreditedStatus")].from = 84;
        propertiesDefinition[bytes32("accreditedStatus")].len = 3;

        propertiesDefinition[bytes32("accreditedStatusUpdated")].code = bytes32("accreditedStatusUpdated");
        propertiesDefinition[bytes32("accreditedStatusUpdated")].bucket = bytes32("general");
        propertiesDefinition[bytes32("accreditedStatusUpdated")].from = 87;
        propertiesDefinition[bytes32("accreditedStatusUpdated")].len = 40;

        propertiesDefinition[bytes32("country")].code = bytes32("country");
        propertiesDefinition[bytes32("country")].bucket = bytes32("general");
        propertiesDefinition[bytes32("country")].from = 127;
        propertiesDefinition[bytes32("country")].len = 16;

        propertiesDefinition[bytes32("insider")].code = bytes32("insider");
        propertiesDefinition[bytes32("insider")].bucket = bytes32("general");
        propertiesDefinition[bytes32("insider")].from = 143;
        propertiesDefinition[bytes32("insider")].len = 1;

        propertiesDefinition[bytes32("lockupExpiration")].code = bytes32("lockupExpiration");
        propertiesDefinition[bytes32("lockupExpiration")].bucket = bytes32("general");
        propertiesDefinition[bytes32("lockupExpiration")].from = 144;
        propertiesDefinition[bytes32("lockupExpiration")].len = 40;

        propertiesDefinition[bytes32("ats")].code = bytes32("ats");
        propertiesDefinition[bytes32("ats")].bucket = bytes32("general");
        propertiesDefinition[bytes32("ats")].from = 184;
        propertiesDefinition[bytes32("ats")].len = 1;

        propertiesDefinition[bytes32("investorId")].code = bytes32("investorId");
        propertiesDefinition[bytes32("investorId")].bucket = bytes32("investorId");
        propertiesDefinition[bytes32("investorId")].from = 0;
        propertiesDefinition[bytes32("investorId")].len = 256;

        propertiesDefinition[bytes32("kycReference")].code = bytes32("kycReference");
        propertiesDefinition[bytes32("kycReference")].bucket = bytes32("kycReference");
        propertiesDefinition[bytes32("kycReference")].from = 0;
        propertiesDefinition[bytes32("kycReference")].len = 256;

        propertiesDefinition[bytes32("amlReference")].code = bytes32("amlReference");
        propertiesDefinition[bytes32("amlReference")].bucket = bytes32("amlReference");
        propertiesDefinition[bytes32("amlReference")].from = 0;
        propertiesDefinition[bytes32("amlReference")].len = 256;

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
