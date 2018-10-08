pragma solidity ^0.4.24;

import "./ERC777.sol";

contract ERC1410 is ERC777 {
    function getDefaultTranches(address _tokenHolder) external view returns (bytes32[]);
    function setDefaultTranches(bytes32[] _tranches) external;
    function balanceOfByTranche(bytes32 _tranche, address _tokenHolder) external view returns (uint256);
    function sendByTranche(bytes32 _tranche, address _to, uint256 _amount, bytes _data) external returns (bytes32);
    function sendByTranches(bytes32[] _tranches, address[] _tos, uint256[] _amounts, bytes _data) external returns (bytes32[]);
    function operatorSendByTranche(bytes32 _tranche, address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData) external returns (bytes32);
    function operatorSendByTranches(bytes32[] _tranches, address[] _froms, address[] _tos, uint256[] _amounts, bytes _data, bytes _operatorData) external returns (bytes32[]);
    function tranchesOf(address _tokenHolder) external view returns (bytes32[]);
    //function defaultOperatorsByTranche(bytes32 _tranche) external view returns (address[]);
    //function authorizeOperatorByTranche(bytes32 _tranche, address _operator) external;
    //function revokeOperatorByTranche(bytes32 _tranche, address _operator) external;
    //function isOperatorForTranche(bytes32 _tranche, address _operator, address _tokenHolder) external view returns (bool);
    function redeemByTranche(bytes32 _tranche, uint256 _amount, bytes _data) external;
    function operatorRedeemByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData) external;

    event SentByTranche(
        bytes32 fromTranche,
        bytes32 toTranche,
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event BurnedByTranche(bytes32 tranche, address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
}