pragma solidity ^0.5.0;

import "../utils/Ownable.sol";
import "../utils/Factory.sol";
import "../utils/AddressArrayLib.sol";
import "./WhitelistModule.sol";

contract IWhitelist is Ownable {
    address[] public validators;

    function addValidator(address validator) public;
    function removeValidator(address validator) public;
    function isValidator(address validator) public view returns(bool);
    function setBucket(address investor, bytes32 bucket, bytes32 value) public;
    function setManyBuckets(address[] memory investors, bytes32[] memory buckets, bytes32[] memory values) public;
    function getBucket(address investor, bytes32 bucket) public view returns(bytes32);
    function getProperty(address investor, bytes32 property) public view returns(bytes32);
    function addProperty(bytes32 code, bytes32 bucket, uint8 from, uint16 len) public;
    function addModule(address moduleAddress) public;
    function removeModule(address moduleAddress) public;
    function isModule(address moduleAddress) public view returns (bool);

    event AddedValidator(address validator);
    event RemovedValidator(address validator);
    event AddedProperty(bytes32 code, bytes32 bucket, uint8 from, uint16 len);
    event AddedModule(address moduleAddress, string moduleType);
    event RemovedModule(address moduleAddress);
    event UpdatedInvestor(address investor, bytes32 bucket, bytes32 value);
}