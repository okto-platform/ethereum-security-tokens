const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const ForcedTransferTokenModuleFactory = artifacts.require("ForcedTransferTokenModuleFactory");
const ForcedTransferTokenModule = artifacts.require("ForcedTransferTokenModule");
const KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
const KycTokenModule = artifacts.require("KycTokenModule");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('ForcedTransferTokenModuleFactory', async(accounts) => {
    let tokenAddress;
    let whitelistAddress;
    let keyModuleAddress;
    let moduleAddress;

    let owner = accounts[0];
    let validator = owner;
    let operator1 = accounts[1];
    let operator2 = accounts[2];
    let investor1 = accounts[3];
    let investor2 = accounts[4];
    let investor3 = accounts[5];

    let trancheUnrestricted = padBytes32(web3.fromUtf8('unrestricted'));
    let trancheLocked = padBytes32(web3.fromUtf8('locked'));

    let dataIssuing = padBytes32(web3.fromUtf8('issuing'));
    let dataUserTransfer = padBytes32(web3.fromUtf8('userTransfer'));
    let dataOperatorTransfer = padBytes32(web3.fromUtf8('operatorTransfer'));

    let generalBucket = web3.fromUtf8('general');
    let propKyc = web3.fromUtf8('kyc');

    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let whitelistFactory = await StandardWhitelistFactory.deployed();
        await whitelistFactory.createInstance(tokenAddress, [validator], [], [], [], [], {from: owner});
        let whitelistsCount = await whitelistFactory.getInstancesCount.call();
        whitelistAddress = await whitelistFactory.getInstance.call(whitelistsCount - 1);

        // the forced transfer module should go first
        let moduleFactory = await ForcedTransferTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await moduleFactory.getInstance.call(modulesCount - 1);

        // we need to configure the kyc module so transfers fail by default
        let keyModuleFactory = await KycTokenModuleFactory.deployed();
        await keyModuleFactory.createInstance(tokenAddress, whitelistAddress, {from: owner});
        let keyModulesCount = await keyModuleFactory.getInstancesCount.call();
        keyModuleAddress = await keyModuleFactory.getInstance.call(keyModulesCount - 1);

        let token = SecurityToken.at(tokenAddress);
        await token.release({from: owner});
    });


    it('force transfer that is not allowed by default', async() => {
        let whitelist = StandardWhitelist.at(whitelistAddress);
        await whitelist.setBucket(investor1, generalBucket, '0x8000000000000000000000000000000000000000000000000000000000000000', {from: validator});
        await whitelist.setBucket(investor2, generalBucket, '0x8000000000000000000000000000000000000000000000000000000000000000', {from: validator});

        let token = SecurityToken.at(tokenAddress);
        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});

        // try to transfer tokens to investor3 and check it fails
        await truffleAssert.reverts(token.sendByTranche(trancheUnrestricted, investor3, 500, dataIssuing, {from: investor1}));

        // force transfer and check if it can be sent
        let module = ForcedTransferTokenModule.at(moduleAddress);
        await module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        let result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');
        result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 1000, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xa6', 'Transfer with different details was still approved');
        result = await token.canSend.call(trancheUnrestricted, operator2, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xa6', 'Transfer with different details was still approved');
        // we can check multiple times without problem
        result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');

        // perform the transfer and make sure it works
        await token.operatorSendByTranche(trancheUnrestricted, investor1, investor3, 500, dataIssuing, dataOperatorTransfer, {from: operator1});
        let balance = await token.balanceOf.call(investor3);
        assert.equal(balance.valueOf(), 500, 'Balance of receiver was not updated');
        balance = await token.balanceOf.call(investor1);
        assert.equal(balance.valueOf(), 500, 'Balance of sender was not updated');

        // make sure that it cannot be done again
        result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xa6', 'Forced transfer can be repeated');
    });


    it('revoke forced transfer', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = ForcedTransferTokenModule.at(moduleAddress);
        await module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        let result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');

        await module.revokeForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        result = await token.canSend.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer, dataOperatorTransfer);
        assert.equal(result[0], '0xa6', 'Forced transfer was not revoked');
    });


    it('only token owner can force a transfer', async() => {
        let module = ForcedTransferTokenModule.at(moduleAddress);
        await truffleAssert.reverts(module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: operator2}));
    });
});