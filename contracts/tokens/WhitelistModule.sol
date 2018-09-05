pragma solidity ^0.4.24;

import "./TokenModule.sol";

contract WhitelistModule is TokenModule {
    function isTransferAllowed
    (
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns(uint) {

    }
}