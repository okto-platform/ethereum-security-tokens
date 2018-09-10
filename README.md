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
