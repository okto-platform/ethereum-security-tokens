pragma solidity ^0.4.24;

import "../interfaces/TransferManager.sol";

contract WhitelistTransferManager is TransferManager {
    function createInstance
    (
        bytes _data
    )
    public
    returns(address)
    {
        return new WhitelistTransferManager(_data);
    }

    function isTransferAllowed
    (
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns(uint);

}