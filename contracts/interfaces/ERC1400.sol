pragma solidity ^0.4.24;

import "./ERC1410.sol";

contract ERC1400 is ERC1410 {
    function getDocument(bytes32 _name) external view returns (string, bytes32);
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external;
    function issuable() external view returns (bool);
    function canSend(address _from, address _to, bytes32 _tranche, uint256 _amount, bytes _data) external view returns (byte, bytes32, bytes32);
    function issueByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data) external;

    event IssuedByTranche(bytes32 indexed tranche, address indexed to, uint256 amount, bytes data);
}