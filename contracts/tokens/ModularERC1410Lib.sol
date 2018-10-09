pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ModularTokenLib.sol";
import "./ModularERC777Lib.sol";
import "./ModularERC1411Lib.sol";

library ModularERC1410Lib {
    using SafeMath for uint256;
    using ModularERC1411Lib for ModularTokenLib.TokenStorage;

    function _getDefaultTranches(ModularTokenLib.TokenStorage storage self, address tokenHolder)
    public view returns (bytes32[])
    {
        // the default implementation returns the tranches available for the token
        // holder in the order they have been added
        // TODO we should allow to override this behavior through modules
        return _tranchesOf(self, tokenHolder);
    }

    function _setDefaultTranches(ModularTokenLib.TokenStorage storage, bytes32[])
    public pure
    {
        // TODO we should allow to override this behavior through a module
        revert("Feature not supported");
    }

    function _getDestinationTranche(ModularTokenLib.TokenStorage storage, bytes32 sourceTranche, address, uint256, bytes)
    pure public returns(bytes32)
    {
        // the default implementation is to transfer to the same tranche
        // TODO we should allow to override this behavior through modules
        return sourceTranche;
    }

    function _balanceOfByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address tokenHolder)
    public view returns (uint256)
    {
        return self.balancesPerTranche[tokenHolder][tranche];
    }

    function _sendByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address to, uint256 amount, bytes data)
    public returns (bytes32)
    {
        require(amount <= self.balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(amount >= 0, "Amount cannot be negative");

        return _internalSendByTranche(self, tranche, address(0), msg.sender, to, amount, data, new bytes(0));
    }

    function _sendByTranches(ModularTokenLib.TokenStorage storage, bytes32[], address[], uint256[], bytes)
    public pure returns (bytes32[])
    {
        // TODO implement this function
        revert("Feature not supported");
    }

    function _operatorSendByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData)
    public returns (bytes32)
    {
        require(_isOperatorFor1410(self, msg.sender, from), "Invalid operator");
        require(amount <= self.balancesPerTranche[from][tranche], "Insufficient funds in tranche");
        require(from != address(0), "Cannot transfer from address 0x0");
        require(to != address(0), "Cannot transfer to address 0x0");
        require(amount >= 0, "Amount cannot be negative");

        return _internalSendByTranche(self, tranche, msg.sender, from, to, amount, data, operatorData);
    }

    function _operatorSendByTranches(ModularTokenLib.TokenStorage storage, bytes32[], address[], address[], uint256[], bytes, bytes)
    public pure returns (bytes32[])
    {
        // TODO implement this function
        revert("Feature not supported");
    }

    function _internalSendByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address operator, address from, address to, uint256 amount, bytes data, bytes operatorData)
    internal returns (bytes32)
    {
        // TODO call tokensToSend if n  eeded
        // TODO call tokensReceived if needed
        // TODO call canSend

        bytes32 destinationTranche = _getDestinationTranche(self, tranche, to, amount, data);
        self.balancesPerTranche[from][tranche] = self.balancesPerTranche[from][tranche].sub(amount);
        self.balancesPerTranche[to][destinationTranche] = self.balancesPerTranche[to][destinationTranche].add(amount);
        // TODO make sure that tranche is added to destination
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        self.balances[from] = self.balances[from].sub(amount);
        self.balances[to] = self.balances[to].add(amount);
        // trigger events
        emit SentByTranche(tranche, destinationTranche, operator, from, to, amount, data, operatorData);
        return destinationTranche;
    }

    function _tranchesOf(ModularTokenLib.TokenStorage storage self, address tokenHolder)
    public view returns (bytes32[])
    {
        return self.tranches[tokenHolder];
    }

    function _redeemByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, uint256 amount, bytes data)
    public
    {
        require(amount <= self.balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");

        _internalRedeemByTranche(self, tranche, address(0), msg.sender, amount, data, new bytes(0));
    }

    function _operatorRedeemByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    public
    {
        require(amount <= self.balancesPerTranche[msg.sender][tranche], "Insufficient funds in tranche");
        require(_isOperatorFor1410(self, msg.sender, tokenHolder), "Invalid operator");
        require(tokenHolder != address(0), "Cannot burn tokens from address 0x0");

        _internalRedeemByTranche(self, tranche, msg.sender, tokenHolder, amount, data, operatorData);
    }

    function _internalRedeemByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address operator, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    internal
    {
        // TODO call tokensToSend if needed
        self.balancesPerTranche[tokenHolder][tranche] = self.balancesPerTranche[tokenHolder][tranche].sub(amount);
        // TODO remove tranche if the balance is zero for the source
        // update global balances
        self.balances[tokenHolder] = self.balances[tokenHolder].sub(amount);
        // reduce total supply of tokens
        self.totalSupply = self.totalSupply.sub(amount);
        // trigger events
        emit BurnedByTranche(tranche, operator, tokenHolder, amount, data, operatorData);
    }

    event SentByTranche(bytes32 fromTranche, bytes32 toTranche, address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event BurnedByTranche(bytes32 tranche, address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    ///////////////////////////////////////////////////////////////////////////
    //
    // Method copied from other libraries to avoid circular dependencies
    //
    ///////////////////////////////////////////////////////////////////////////

    // Copied from ModularERC777Lib
    function _isOperatorFor1410(ModularTokenLib.TokenStorage storage self, address operator, address tokenHolder)
    internal view returns (bool)
    {
        if (_isDefaultOperator1410(self, operator)) {
            return true;
        }
        return self.operators[tokenHolder][operator];
    }

    // Copied from ModularERC777Lib
    function _isDefaultOperator1410(ModularTokenLib.TokenStorage storage self, address operator)
    internal view returns (bool)
    {
        for (uint i = 0; i < self.defaultOperators.length; i++) {
            if (self.defaultOperators[i] == operator) {
                return true;
            }
        }
        return false;
    }
}