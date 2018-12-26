pragma solidity 0.5.0;

import "../utils/Ownable.sol";

contract Module is Ownable {
    enum Feature {TransferValidator, TransferListener, TranchesManager, WhitelistListener}

    function getFeatures() public view returns(Feature[] memory);
}