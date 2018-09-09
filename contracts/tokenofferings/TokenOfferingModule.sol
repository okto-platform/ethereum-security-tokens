pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TokenOfferingModule is Ownable {
    enum AllocationAllowanceResult {NotAllowed, Allowed, ForceNotAllowed, ForceAllowed}

    address tokenOfferingAddress;

    event AllocationRejected(string code, string message);

    constructor(address _tokenOfferingAddress)
    public
    {
        tokenOfferingAddress = _tokenOfferingAddress;
    }

    function allowAllocation(address _to, uint256 _amount)
    public returns(AllocationAllowanceResult);
}