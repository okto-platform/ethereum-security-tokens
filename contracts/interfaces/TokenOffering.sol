pragma solidity ^0.4.24;

interface TokenOffering {
    function createInstance
    (
        bytes _data
    )
    public
    returns(address);
}