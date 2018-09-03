pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../transfermanagers/TransferManager.sol";

contract SlingrSecurityToken is StandardToken,Ownable {

    address tokenOfferingAddress;
    TransferManager[] transferManagers;

    modifier onlyTokenOffering {
        require(msg.sender == tokenOfferingAddress);
        _;
    }

    constructor() {
    }

    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        // TODO execute transfer managers at this point
        return super.transfer(_to, _value);
    }


    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        // TODO execute transfer managers at this point
        return super.transferFrom(_from, _to, _value);
    }

    function mint(
        address _to,
        uint256 _amount
    )
    public
    onlyTokenOffering
    {
        // TODO only token offering contract can call this method
    }

    function setWhitelist(
        address _whitelistAddress
    )
    public
    onlyOwner
    {
        // TODO this is the whitelist used by the secondary market
    }

    function setTokenOffering(
        address _tokenOfferingAddress
    )
    public
    onlyOwner
    {
        // TODO this is to configure the token offering contract
    }

    function addTransferManager(
        address _transferManagerAddress
    )
    public
    onlyOwner
    {
        transferManagers
    }

    function release()
    public
    onlyOwner
    {
        // TODO
    }
}
