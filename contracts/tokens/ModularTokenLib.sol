pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library ModularTokenLib {
    using SafeMath for uint256;

    enum TokenStatus {Draft, Released}

    struct TokenStorage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 granularity;
        uint256 totalSupply;
        mapping(address => mapping(bytes32 => uint256)) balancesPerTranche;
        mapping(address => uint256) balances;
        mapping(address => bytes32[]) tranches;
        mapping (address => mapping (address => uint256)) allowed;
        address[] defaultOperators;
        mapping(address => mapping(address => bool)) operators;
        bool issuable;
        TokenStatus status;
    }
}