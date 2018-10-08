pragma solidity ^0.4.24;

library TokenUtilsLibrary {
    enum TokenStatus {Draft, Released}

    struct TokenStorage {
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public granularity;
        uint256 public totalSupply;
        mapping(address => mapping(bytes32 => uint256)) internal balancesPerTranche;
        mapping(address => uint256) internal balances;
        mapping(address => bytes32[]) internal tranches;
        mapping (address => mapping (address => uint256)) internal allowed;
        address[] public defaultOperators;
        mapping(address => mapping(address => bool)) operators;
        bool public issuable = true;
        TokenStatus public status;
    }
}