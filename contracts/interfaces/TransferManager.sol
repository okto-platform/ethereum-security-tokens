pragma solidity ^0.4.24;

interface TransferManager {
    enum TransferAllowanceResult {NotAllowed, Allowed, ForceNowAllowed, ForceAllowed}

    function createInstance
    (
        bytes _data
    )
    public
    returns(address);

    function isTransferAllowed
    (
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns(uint);
}