pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ModularTokenLib.sol";
import "./ModularERC1410Lib.sol";

library ModularERC777Lib {
    using SafeMath for uint256;
    using ModularERC1410Lib for ModularTokenLib.TokenStorage;

    function _name(ModularTokenLib.TokenStorage storage self)
    public view returns(string)
    {
        return self.name;
    }

    function _symbol(ModularTokenLib.TokenStorage storage self)
    public view returns(string)
    {
        return self.symbol;
    }

    function _decimals(ModularTokenLib.TokenStorage storage self)
    public view returns(uint8)
    {
        return self.decimals;
    }

    function _granularity(ModularTokenLib.TokenStorage storage self)
    public view returns(uint256)
    {
        return self.granularity;
    }

    function _defaultOperators(ModularTokenLib.TokenStorage storage self)
    public view returns(address[])
    {
        return self.defaultOperators;
    }

    function _authorizeOperator(ModularTokenLib.TokenStorage storage self, address operator)
    public
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot authorize token holder");

        if (!_isDefaultOperator(self, operator)) {
            self.operators[msg.sender][operator] = true;
        }
        emit AuthorizedOperator(operator, msg.sender);
    }

    function _revokeOperator(ModularTokenLib.TokenStorage storage self, address operator)
    public
    {
        require(operator != address(0), "Valid operator must be provided");
        require(operator != msg.sender, "Cannot revoke token holder");

        if (!_isDefaultOperator(self, operator)) {
            self.operators[msg.sender][operator] = false;
        }
        emit RevokedOperator(operator, msg.sender);
    }

    function _isOperatorFor(ModularTokenLib.TokenStorage storage self, address operator, address tokenHolder)
    public view returns (bool)
    {
        if (_isDefaultOperator(self, operator)) {
            return true;
        }
        return self.operators[tokenHolder][operator];
    }

    function _isDefaultOperator(ModularTokenLib.TokenStorage storage self, address operator)
    public view returns (bool)
    {
        for (uint i = 0; i < self.defaultOperators.length; i++) {
            if (self.defaultOperators[i] == operator) {
                return true;
            }
        }
        return false;
    }

    function _send(ModularTokenLib.TokenStorage storage self, address to, uint256 amount, bytes data)
    public
    {
        require(amount <= self.balances[msg.sender], "Insufficient funds");
        require(to != address(0), "Cannot transfer to address 0x0");

        _internalSend(self, address(0), msg.sender, to, amount, data, new bytes(0));
    }

    function _operatorSend(ModularTokenLib.TokenStorage storage self, address from, address to, uint256 amount, bytes data, bytes operatorData)
    public
    {
        require(_isOperatorFor(self, msg.sender, from), "Invalid operator");
        require(amount <= self.balances[from], "Insufficient funds");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(from != address(0), "Cannot transfer from address 0x0");

        _internalSend(self, msg.sender, from, to, amount, data, operatorData);
    }

    function _internalSend(ModularTokenLib.TokenStorage storage self, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    public
    {
        // TODO if `to` is a contract we need to call function `tokensToSend`
        // TODO implement `tokensReceived`
        // TODO check granularity

        // go through default tranches to
        bytes32[] memory defaultTranches = self._getDefaultTranches(from);
        uint256 pendingAmount = amount;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (self.balancesPerTranche[from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = self.balancesPerTranche[from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                if (operator == address(0)) {
                    self._sendByTranche(defaultTranches[i], to, amountToSubtract, data);
                } else {
                    self._operatorSendByTranche(defaultTranches[i], from, to, amountToSubtract, data, operatorData);
                }
            }
        }

        // check that all tokens could be transferred
        require(pendingAmount == 0, "Insufficient funds in default tranches");

        // trigger events
        emit Sent(operator, from, to, amount, data, operatorData);
        emit Transfer(from, to, amount);
    }

    function _burn(ModularTokenLib.TokenStorage storage self, uint256 amount, bytes data)
    public
    {
        // TODO call `tokensToSend`
        require(amount <= self.balances[msg.sender], "Insufficient funds");

        _internalBurn(self, address(0), msg.sender, amount, data, new bytes(0));
    }

    function _operatorBurn(ModularTokenLib.TokenStorage storage self, address from, uint256 amount, bytes data, bytes operatorData)
    public
    {
        require(_isOperatorFor(self, msg.sender, from), "Invalid operator");
        require(amount <= self.balances[msg.sender], "Insufficient funds");
        require(from != address(0), "Cannot transfer from address 0x0");

        _internalBurn(self, msg.sender, from, amount, data, operatorData);
    }

    function _internalBurn(ModularTokenLib.TokenStorage storage self, address operator, address from, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        // TODO if `to` is a contract we need to call function `tokensToSend`
        // TODO check granularity

        // go through default tranches to
        bytes32[] memory defaultTranches = self._getDefaultTranches(from);
        uint256 pendingAmount = amount;
        for (uint i = 0; i < defaultTranches.length; i++) {
            if (self.balancesPerTranche[from][defaultTranches[i]] > 0) {
                uint256 trancheBalance = self.balancesPerTranche[from][defaultTranches[i]];
                uint256 amountToSubtract = pendingAmount;
                if (trancheBalance < amountToSubtract) {
                    amountToSubtract = trancheBalance;
                    pendingAmount = pendingAmount.sub(amountToSubtract);
                }
                if (operator == address(0)) {
                    self._redeemByTranche(defaultTranches[i], amountToSubtract, data);
                } else {
                    self._operatorRedeemByTranche(defaultTranches[i], from, amountToSubtract, data, operatorData);
                }
            }
        }

        // check that all tokens could be transferred
        require(pendingAmount == 0, "Insufficient funds in default tranches");

        // trigger events
        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}