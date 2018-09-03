pragma solidity ^0.4.24;

contract TransferManager {
    enum TransferAllowanceResult {NotAllowed, Allowed, ForceNowAllowed, ForceAllowed}

    function isTransferAllowed
    (
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns(uint);
}