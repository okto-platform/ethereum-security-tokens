pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ModularTokenLib.sol";
import "./ModularERC777Lib.sol";
import "./ModularERC1410Lib.sol";

library ModularERC1411Lib {
    using SafeMath for uint256;

    function _canSend(ModularTokenLib.TokenStorage storage self, address, address to, bytes32 tranche, uint256 amount, bytes data)
    public pure returns (byte, bytes32, bytes32)
    {
        bytes32 destinationTranche = _getDestinationTranche1411(self, tranche, to, amount, data);
        // TODO we need to go through all the transfer modules and check if we can send
        return (0xA0, bytes32(0x0), destinationTranche);
    }

    function _issuable(ModularTokenLib.TokenStorage storage self)
    public view returns(bool)
    {
        return self.issuable;
    }

    function _issueByTranche(ModularTokenLib.TokenStorage storage self, bytes32 tranche, address tokenHolder, uint256 amount, bytes data)
    public
    {
        require(tokenHolder != address(0), "Cannot issue tokens to address 0x0");
        // TODO we should only allow offering modules to do this
        require(self.issuable, "It is not possible to issue more tokens");
        require(_isDefaultOperator1411(self, msg.sender), "Only default operators can do this");

        self.balancesPerTranche[tokenHolder][tranche] = self.balancesPerTranche[tokenHolder][tranche].add(amount);
        self.balances[tokenHolder] = self.balances[tokenHolder].add(amount);
        self.totalSupply = self.totalSupply.add(amount);

        emit IssuedByTranche(tranche, tokenHolder, amount, data);
    }

    event IssuedByTranche(bytes32 indexed tranche, address indexed to, uint256 amount, bytes data);

    ///////////////////////////////////////////////////////////////////////////
    //
    // Method copied from other libraries to avoid circular dependencies
    //
    ///////////////////////////////////////////////////////////////////////////

    // Copied from ModularERC1410Lib
    function _getDestinationTranche1411(ModularTokenLib.TokenStorage storage, bytes32 sourceTranche, address, uint256, bytes)
    pure internal returns(bytes32)
    {
        // the default implementation is to transfer to the same tranche
        // TODO we should allow to override this behavior through modules
        return sourceTranche;
    }

    // Copied from ModularERC777Lib
    function _isOperatorFor1411(ModularTokenLib.TokenStorage storage self, address operator, address tokenHolder)
    internal view returns (bool)
    {
        if (_isDefaultOperator1411(self, operator)) {
            return true;
        }
        return self.operators[tokenHolder][operator];
    }

    // Copied from ModularERC777Lib
    function _isDefaultOperator1411(ModularTokenLib.TokenStorage storage self, address operator)
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