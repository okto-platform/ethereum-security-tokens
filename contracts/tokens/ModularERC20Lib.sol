pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ModularTokenLib.sol";
import "./ModularERC777Lib.sol";

library ModularERC20Lib {
    using SafeMath for uint256;
    using ModularERC777Lib for ModularTokenLib.TokenStorage;

    function _totalSupply(ModularTokenLib.TokenStorage storage self)
    public view returns(uint256)
    {
        return self.totalSupply;
    }

    function _balanceOf(ModularTokenLib.TokenStorage storage self, address owner)
    public view returns (uint256)
    {
        return self.balances[owner];
    }

    function _transfer(ModularTokenLib.TokenStorage storage self, address to, uint256 amount)
    public returns (bool)
    {
        require(amount <= self.balances[msg.sender], "Insufficient funds");
        require(to != address(0), "Cannot transfer to address 0x0");

        self._internalSend(address(0), msg.sender, to, amount, new bytes(0), new bytes(0));
        return true;
    }

    function _allowance(ModularTokenLib.TokenStorage storage self, address owner, address spender)
    public view returns (uint256)
    {
        return self.allowed[owner][spender];
    }

    function _transferFrom(ModularTokenLib.TokenStorage storage self, address from, address to, uint256 amount)
    public returns (bool)
    {
        require(amount <= self.balances[from]);
        require(amount <= self.allowed[from][msg.sender]);
        require(to != address(0));

        self._internalSend(address(0), from, to, amount, new bytes(0), new bytes(0));
        self.allowed[from][msg.sender] = self.allowed[from][msg.sender].sub(amount);
        return true;
    }

    function _approve(ModularTokenLib.TokenStorage storage self, address spender, uint256 amount)
    public returns (bool)
    {
        self.allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}