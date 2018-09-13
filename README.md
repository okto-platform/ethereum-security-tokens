# SLINGR Security Tokens

Protocol for security token smart contracts for Transfer Agents Powered by SLINGR

## Overview

![High level overview](https://github.com/slingr-stack/slingr-security-tokens/blob/master/docs/slingr-tokens.png?raw=true)

The `Token` is a ERC-20 compatible contract that holds balances and have the methods to transfer tokens from
on wallet to another. Additionally the SLINGR Security Token has some additional features:

- Allow to add/remove modules that can extend the features of a token.
- Allow to configure a token offering.
- Hooks to verify transfers by modules. For example it could be a module that checks that the destination wallet is 
  whitelisted.
- Minting and burning of tokens that can be used by token offerings or other modules.
- Checkpoints to know the balance of any token holder or total amount of tokens on specific points in time.
- Management of permissions through roles.

`Module` represents a contract associated to a token that:

- Provides callbacks for hooks available in the token, like hooks to verify transfers.
- Can access some special functions in the token's contract in order to provide additional features. For
  example minting/burning methods are only available to modules.
- Can provide features to the token. For example, they can provide features like KYC compliance or reissuane 
  of tokens. 

`Token Offering` is in charge of minting tokens based on the rules of the token offering. Additionally a token
offering can have modules to add more features to it, like a hard/soft cap, KYC compliance, etc. This is
represented by `Token Offering Module`.

`Whitelist` keeps information about addresses and properties they have, like if they have been passed KYC validation,
country, expiration, etc. This information is used by modules and token offerings to allow or reject operations.

`Multisig Wallet` is a wallet owned by many wallets (that could be another multisig wallet as well). This is
important to define security schemes. For example an operation might need to be approved by three different
departments. In this case, each department would be an owner of the multisig wallet to execute that operation. At
the same time, the wallet of each department could be a multisig wallet where owners are the people with 
permissions to approve transactions on behalf of the department.

## Creating a token

In order to create a new token you need to use the `SlingrSecurityTokenFatory` contract. It will allow you to
setup a new token contract.

This contract will be a in a draft state, which means you can configure the token, but cannot operate (mint,
make transfers, etc.). During the configuration you will probably perform the following operations:

- *Add modules*: modules affect how the token will be have and what are the features of it. While the token
  is in draft status, it is possible to add/remove modules. You won't be allowed to do so once the token is
  released.
- *Set a token offering*:  token offerings are a special kind of module that will be in charge of the
  initial minting of tokens.
- *Change token information*: this is changing name, description, etc.

Once all the configuration has happened, you should release the token by using the method `release` in
the contract.

## Extending tokens

Modules allow you to extend the features in a token. They can:

- Allow/reject transfers
- Mint tokens
- Burn tokens
- Create a checkpoint

With the above operations it is possible to create modules that do different things like:

- Allow/reject transactions based on a whitelist
- Reissue tokens
- Set a limit in the percentage of tokens owned by an investor

Token modules will need to follow the `TokenModule` interface:

```
contract TokenModule is Ownable {
    enum TransferAllowanceResult {NotAllowed, Allowed, ForceNotAllowed, ForceAllowed}

    address tokenAddress;

    modifier onlyTokenOwner()
    {
        SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
        require(msg.sender == token.owner(), "Only token owner can execute this operation");
        _;
    }

    constructor(address _tokenAddress)
    public
    {
        tokenAddress = _tokenAddress;
    }

    function isTransferAllowed(address _from, address _to, uint256 _amount)
    public returns(TransferAllowanceResult);
}
```

Additionally we suggest to provide a factory for your token so it is easy to create. You can find
factory samples in `KycOfferingModuleFactory`.

If the token wants to validate transactions, the method `isTransferAllowed(address, address, uint256)`
has to be implemented. This method can return:
 
- `Allow`: the module allows the transaction, but another module could still not allowed it.
- `ForceAllow`: the transaction will be allowed immediately and no other module will be evaluated.
- `NotAllowed`: the module does not allow the transaction, but another module could still force to allow it.
- `ForceNotAllowed`: the transaction is not allowed and no other moddule will be evaluated.

Modules will be called in the same order they were added to the token.

Additionally, the module can call internal methods in the token like `mint` or `burn`. This way
you could create a module to reissue tokens:

```
function reissueTokens(address _from, address _to)
public onlyTokenOwner
{
    SlingrSecurityToken token = SlingrSecurityToken(tokenAddress);
    uint256 balance = token.balanceOf(token);
    token.burn(_from, balance);
    token.mint(_to, balance);
    emit TokensReissued(_from, _to, balance);
}
```

So basically the module has a public function called `reissueTokens` that uses the internal `mint`
and `burn` functions in the token.

## Extending token offerings

Token offerings are associated to a token and they perform the initial minting of tokens. All token
offerings should extend from `TokenOffering`, which provides the following things:

- Set and start and end date for the offering
- The list of investors and tokens allocated
- The function `allocateTokens` to allow to allocate tokens for an investor
- Add modules to control how the offering will be performed

The `TokenOffering` contract is abstract and does not say anything on how investors will get their
tokens. It could be an external tool to rise the funds and passing the list to a token offering
contract that extends from `TokenOffering`, or it could be a token offering that accepts payments
in ETH or any other token.

Similar to what happens with tokens, token offerings can also have modules. They should extend the
`TokenOfferingModule` contract:

```
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
```

Basically modules need to implement the `allowAllocation` module to determine if that allocation
is valid.

As with token modules, it is recommended that they provide a factory contract, like 
`TokensHardCapModuleFactory` for example.

## Custom whitelists

A whitelist associates information to an address. This information could be if they passed KYC,
the country they belong to, or and ID hash of the person. This is useful when security tokens
need to comply with regulations.

You can see how whitelists are used in `KycOfferingModule` or `KycTokenModule`.

Whitelist will extend the `Whitelist` contract and then in the implementation they should indicate
which will be the properties hold for each address. This is for example the `StandardWhitelist`:

```
contract StandardWhitelist is Whitelist {
    mapping (string => PropertyType) propertiesType;

    constructor()
    public
    {
        propertiesType["kyc"] = PropertyType.Boolean;
        propertiesType["expiration"] = PropertyType.Number;
        propertiesType["country"] = PropertyType.String;
    }

    function isValidValueForProperty(string _property, string)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.String);
    }


    function isValidValueForProperty(string _property, bool)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.Boolean);
    }

    function isValidValueForProperty(string _property, uint)
    public returns(bool)
    {
        return checkPropertyType(_property, PropertyType.Number);
    }

    function checkPropertyType(string _property, PropertyType _type)
    public returns(bool)
    {
        PropertyType propertyType = propertiesType[_property];
        return propertyType == _type;
    }
}
```

In addition it is recommended to have a factory contract, like `StandardWhitelistFactory`.