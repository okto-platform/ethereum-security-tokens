pragma solidity ^0.4.24;

import "./TransferManager.sol";

contract WhitelistTransferManager is TransferManager {
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