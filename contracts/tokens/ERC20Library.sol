pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library ERC20Library {
    using SafeMath for uint256;

    function totalSupply()
    public view returns(uint256)
    {
        return totalSupply;
    }

    function balanceOf(address _owner)
    public view returns (uint256)
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
    isReleased
    public returns (bool)
    {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(_to != address(0), "Cannot transfer to address 0x0");
        internalSend(address(0), msg.sender, _to, _value, new bytes(0), new bytes(0));
        return true;
    }

    function allowance(address _owner, address _spender)
    isReleased
    public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value)
    isReleased
    public returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        // go through default tranches to
        // TODO see if we can refactor this so we don't copy that much code
        bytes32[] memory defaultTranches = internalGetDefaultTranches(_from);
        uint256 pendingAmount = _value;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (balancesPerTranche[_from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = balancesPerTranche[_from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                bytes32 destinationTranche = internalGetDestinationTranche(defaultTranches[i], _to, amountToSubtract, new bytes(0));
                balancesPerTranche[_from][defaultTranches[i]] = balancesPerTranche[_from][defaultTranches[i]].sub(amountToSubtract);
                balancesPerTranche[_to][destinationTranche] = balancesPerTranche[_to][destinationTranche].add(amountToSubtract);
                // TODO make sure that tranche is added to destination
                // TODO remove tranche if the balance is zero for the source
                emit SentByTranche(defaultTranches[i], destinationTranche, address(0), _from, _to, amountToSubtract, new bytes(0), new bytes(0));
            }
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    isReleased
    public returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}