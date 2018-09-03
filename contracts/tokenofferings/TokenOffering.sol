pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract TokenOffering is Pausable {
    function setWhitelist
    (
        address _whitelistAddress
    )
    public;

    function setToken
    (
        address _tokenAddress
    )
    public;

    function start()
    public
    onlyOwner;

    function end()
    public
    onlyOwner;

    function mint()
    public
    onlyOwner;
}