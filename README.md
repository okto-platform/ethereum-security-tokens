# OKTO Security Tokens

Ethereum protocol for security token for Transfer Agents Powered by OKTO

## Overview

The OKTO Security Token is a set of smart contracts for the Ethereum blockchain that allow to create tokens that 
can comply with the regulations that apply for securities. Some of the features are backed inside the token, but most 
of them are provided via modules. Token modules allow to extend the security token to meet more complex needs that are
not supported yet.

![High level overview](https://github.com/okto-platform/ethereum-security-tokens/blob/master/docs/security-tokens-overview.png?raw=true)

The `Security Token` was created following the proposal ERC-1411 (still in draft), but it is important to notice that
it is not fully compatible with it. Maybe in the future some additional features might be added to make it compatible.

By default (without any module) a token has the following features:

- Keeps the tokens ledger, allowing to know the list of investors and how much tokens they have
- Support for tranches to have tokens with different properties
- Token operators, meant for transfer agent duties
- Modules management to add more features to the token
- Issuing and redemption of tokens
- Read-only compatible with ERC-20 (does not support transfers using ERC-20 protocol)

A `Token Module` can implement any of those interfaces (more than one if needed):

- `Transfer Validator`: this interface is to validate tokens transfers, including issuance and redemption. The module
  will be able to approve, reject or forced to approve a specific transaction.
- `Transfer Listener`: this interface allows the module to listen on-chain to all transfers done in the token.
- `Tranches Manager`: this interface allows the module to decide how branches will be managed. For example decide
  the destination branch when sending tokens to another investor.

Some of the built-in modules are:

- `OfferingTokenModule`: this is an offering module that allows to set a period for an initial offering where tokens
  will be issued.
- `KycTokenModuleTokenModule`: verifies that investors passed KYC before being able to receive/buy tokens.
- `InvestorsLimitTokenModule`: makes sure that the number of investors does not go above a predefined limit.
- `SupplyLimitTokenModule`: sets a limit to the total supply of tokens.
- `ForcedTransferTokenModule`: allow the token owner to approve a transaction that otherwise would be invalid.

## Whitelists

Whitelists keep information about addresses and properties they have, like if they have been passed KYC validation,
country, expiration, etc. This information can be used by modules and token offerings to allow or reject operations.

![High level overview](https://github.com/okto-platform/ethereum-security-tokens/blob/master/docs/whitelists.png?raw=true)

- `Whitelist`: this is a generic whitelist that information in a `unit256` field per each address. That means you
  have 256 bits to store information associated to any address with tools to define the properties and boundaries
  in bits for each one.
- `StandardWhitelist`: provides some predefined fields for the whitelists, like KYC flag, country, expiration, etc.

In most cases you will want to use the `StandardWhitelist`.

## Multisig Wallets

The multisig wallet is a wallet owned by many wallets (that could be another multisig wallet as well). This is
important to define security schemes. For example an operation might need to be approved by three different
departments. In this case, each department would be an owner of the multisig wallet to execute that operation. At
the same time, the wallet of each department could be a multisig wallet where owners are the people with 
permissions to approve transactions on behalf of the department.

The multisig wallet in used is the one created by Gnosis. Please go to [Gnosis Multisig Wallet](https://github.com/gnosis/MultiSigWallet) 
for more information.

## Creating a token

The process to create a new token is the following:

- *Create token*: the token can be created using the `SecurityTokenFactory`. This will create a new token contract
  in draft status (cannot be operated until it is released).
- *Add modules*: after the creation of the token, modules should be added to support the features needed by the token.
  Every module has its own factory (i.e. `KycTokenModuleFactory` for the `KycTokenModule` module) that allows to
  create a new module contract and will automatically attach it to the token.
- *Release the token*: once the token is configured as desired, the token should be released. After the token is
  released no additional modules can be added to the token.

## Extending tokens

If the token has features that are needed but they are not provided by the token, it is possible to create token
modules to support them. A module token must implement the `TokenModule` interface and implement at least one of
`TransferValidatorTokenModule`, `TransferListenerTokenModule` or `TranchesManagerTokenModule`.

Here is the sample of the module to enforce a maximum of investors:

```
contract InvestorsLimitTokenModule is TransferValidatorTokenModule,TransferListenerTokenModule,TokenModule {
    uint256 public limit;
    uint256 public numberOfInvestors;

    constructor(address _tokenAddress, uint256 _limit)
    TokenModule(_tokenAddress)
    public
    {
        require(_limit > 0, "Limit must be greater than zero");

        limit = _limit;
    }

    function getFeatures()
    public view returns(Module.Feature[])
    {
        Module.Feature[] memory features = new Module.Feature[](2);
        features[0] = Module.Feature.TransferValidator;
        features[1] = Module.Feature.TransferListener;
        return features;
    }


    function validateTransfer(bytes32, bytes32, address, address from, address to, uint256 amount, bytes, bytes)
    public view returns (byte, string)
    {
        SecurityToken token = SecurityToken(tokenAddress);
        if (to != address(0) && token.balanceOf(to) == 0) {
            // if the sender is transferring all its tokens, then we can assume there will be one investor less
            uint256 diff = (from != address(0) && token.balanceOf(from) == amount) ? 1 : 0;
            // this is a new investor so we need to check limit
            if ((numberOfInvestors - diff) >= limit) {
                return (0xA8, "Maximum number of investors reached");
            }
        }
        return (0xA1, "Approved");
    }

    function transferDone(bytes32, bytes32, address, address from, address to, uint256 amount, bytes, bytes)
    public
    {
        SecurityToken token = SecurityToken(tokenAddress);
        if (to != address(0) && token.balanceOf(to) == amount) {
            // it means that this is a new investor as all the tokens are the ones that were transferred in this operation
            numberOfInvestors++;
        }
        if (from != address(0) && token.balanceOf(from) == 0) {
            // decrease the number of investors as the sender does not have any tokens after the transaction
            numberOfInvestors--;
        }
    }
}

contract InvestorsLimitTokenModuleFactory is Factory {
    function createInstance(address _tokenAddress, uint256 _limit)
    public returns(address)
    {
        InvestorsLimitTokenModule instance = new InvestorsLimitTokenModule(_tokenAddress, _limit);
        instance.transferOwnership(msg.sender);
        addInstance(instance);
        // attach module to token
        SecurityToken token = SecurityToken(_tokenAddress);
        token.addModule(instance);
        return instance;
    }
}
```

As you can see it implements the required `TokenModule` interface and additionally it implements:
 
- `TransferValidatorTokenModule`: this is to reject transfers that will increase the number of investors above the limit.
- `TransferListenerTokenModule`: to update the number of investors if needed when a transaction, issuing or redemption
  is done.

Some modules that could be created are:

- Restrictions to transfer tokens between jurisdictions
- Checkpoint module to keep track of amounts at specific points in time
- Dividends module to pay dividends to investors in Ether
- Voting module to allow investors to vote
- Proxy module to allow investors to define a proxy for voting

## Factories addresses

These are the current contract addresses of the factories on Ropsten:

```
SecurityTokenFactory                 => 0x90A72deBA74d04bdC11c66429bcDeDa9C787De70
RestrictSenderTokenModuleFactory     => 0x83d07312CE1d15832791574b8208056731e9bFB0
KycTokenModuleFactory                => 0xA1F2CDeD2FEef1C7Fe4E51064A7fDE47fCE06747
InvestorsLimitTokenModuleFactory     => 0xBaFc429eC807E211e3B6811213f01f8cFE979a04
SupplyLimitTokenModuleFactory        => 0x1C7a97a80d083ddb6d41BC271Fc7356096d065E9
ForcedTransferTokenModuleFactory     => 0xF0C652bfAfA7D682f84451E29278B377699c59e3
OfferingTokenModuleFactory           => 0x6A96bd1C23cF6230FBF4547e0333923437C2716d
WhitelistFactory                     => 0xEB69F4703EeFEf5e640c076447F6fd723CFeb97f
StandardWhitelistFactory             => 0xf27597371C54628403eb665946CE3616800F5D14
MultiSigWalletFactory                => 0x6eedb6f85012c57a2789860ad27eee8be7821d8e
```

Libraries:

```
AddressArrayLib  => 0x3C904f91aBBc45195f33Db5336c0C20Ba6cBe242
Bytes32ArrayLib  => 0x44736Ba37e0304B8075E0f825e027991AbC73f4E
```

## Disclaimer

This protocol is still in development and should not be used for production tokens yet.
