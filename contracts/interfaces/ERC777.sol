pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract ERC777 is ERC20 {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function granularity() external view returns (uint256);

    function defaultOperators() external view returns (address[]);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function send(address to, uint256 amount, bytes data) external;
    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData) external;

    function burn(uint256 amount, bytes data) external;
    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}