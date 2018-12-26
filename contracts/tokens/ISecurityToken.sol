pragma solidity 0.5.0;

import "../utils/Pausable.sol";

contract ISecurityToken is Pausable {
    // ERC-20

    uint256 public totalSupply;

    function balanceOf(address tokenHolder) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // OKTO Security Token

    string public name;
    string public symbol;
    uint8 public decimals;
    address public whitelistAddress;
    address[] public operators;
    bool public released;

    // Modules handling
    function addModule(address moduleAddress) public;
    function removeModule(address moduleAddress) public;
    function release() public;

    // Operators handling
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperator(address operator) public view returns (bool);

    // Tokens handling
    function balanceOfByTranche(bytes32 tranche, address tokenHolder) public view returns (uint256);
    function getDestinationTranche(bytes32 sourceTranche, address from, uint256 amount, bytes memory data) public view returns(bytes32);
    function canTransfer(bytes32 tranche, address operator, address from, address to, uint256 amount, bytes memory data) public view returns (byte, string memory, bytes32);
    function transferByTranche(bytes32 tranche, address to, uint256 amount, bytes memory data) public returns (bytes32);
    function operatorTransferByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes memory data) public returns (bytes32);
    function tranchesOf(address tokenHolder) public view returns (bytes32[] memory);
    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes memory data) public;
    function burnByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes memory data) public;

    // Events
    event AddedModule(address moduleAddress, string moduleType);
    event RemovedModule(address moduleAddress);
    event Released();
    event AuthorizedOperator(address indexed operator);
    event RevokedOperator(address indexed operator);
    event TransferByTranche(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data);
    event IssuedByTranche(bytes32 tranche, address indexed operator, address indexed to, uint256 amount, bytes data);
    event BurnedByTranche(bytes32 tranche, address indexed operator, address indexed from, uint256 amount, bytes data);
}
