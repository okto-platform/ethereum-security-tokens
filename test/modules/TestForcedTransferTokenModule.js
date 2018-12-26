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
    let kycModuleAddress;
    let moduleAddress;

    let owner = accounts[0];
    let validator = owner;
    let operator1 = accounts[1];
    let operator2 = accounts[2];
    let investor1 = accounts[3];
    let investor2 = accounts[4];
    let investor3 = accounts[5];

    let trancheUnrestricted = padBytes32(web3.utils.fromUtf8('unrestricted'));
    let trancheLocked = padBytes32(web3.utils.fromUtf8('locked'));

    let dataIssuing = padBytes32(web3.utils.fromUtf8('issuing'));
    let dataUserTransfer = padBytes32(web3.utils.fromUtf8('userTransfer'));

    let generalBucket = web3.utils.fromUtf8('general');
    let propKyc = web3.utils.fromUtf8('kycStatus');

    it('configure module', async() => {
        let whitelistFactory = await StandardWhitelistFactory.deployed();
        await whitelistFactory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await whitelistFactory.getInstancesCount.call();
        whitelistAddress = await whitelistFactory.getInstance.call(whitelistsCount - 1);

        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, whitelistAddress, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        // the forced transfer module should go first
        let moduleFactory = await ForcedTransferTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await moduleFactory.getInstance.call(modulesCount - 1);

        // we need to configure the kyc module so transfers fail by default
        let kycModuleFactory = await KycTokenModuleFactory.deployed();
        await kycModuleFactory.createInstance(tokenAddress, {from: owner});
        let kycModulesCount = await kycModuleFactory.getInstancesCount.call();
        kycModuleAddress = await kycModuleFactory.getInstance.call(kycModulesCount - 1);

        let whitelist = await StandardWhitelist.at(whitelistAddress);
        let token = await SecurityToken.at(tokenAddress);
        await token.addModule(moduleAddress, {from: owner});
        await token.addModule(kycModuleAddress, {from: owner});
        await token.release({from: owner});
    });


    it('force transfer that is not allowed by default', async() => {
        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await whitelist.setBucket(investor1, generalBucket, '0x4000000000000000000000000000000000000000000000000000000000000000', {from: validator});
        await whitelist.setBucket(investor2, generalBucket, '0x4000000000000000000000000000000000000000000000000000000000000000', {from: validator});

        let token = await SecurityToken.at(tokenAddress);
        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});

        // try to transfer tokens to investor3 and check it fails
        await truffleAssert.reverts(token.transferByTranche(trancheUnrestricted, investor3, 500, dataIssuing, {from: investor1}));

        // force transfer and check if it can be sent
        let module = await ForcedTransferTokenModule.at(moduleAddress);
        await module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        let result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');
        result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 1000, dataUserTransfer);
        assert.equal(result[0], '0xa6', 'Transfer with different details was still approved');
        result = await token.canTransfer.call(trancheUnrestricted, operator2, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xa6', 'Transfer with different details was still approved');
        // we can check multiple times without problem
        result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');

        // perform the transfer and make sure it works
        await token.operatorTransferByTranche(trancheUnrestricted, investor1, investor3, 500, dataIssuing, {from: operator1});
        let balance = await token.balanceOf.call(investor3);
        assert.equal(balance.valueOf(), 500, 'Balance of receiver was not updated');
        balance = await token.balanceOf.call(investor1);
        assert.equal(balance.valueOf(), 500, 'Balance of sender was not updated');

        // make sure that it cannot be done again
        result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xa6', 'Forced transfer can be repeated');
    });


    it('revoke forced transfer', async() => {
        let token = await SecurityToken.at(tokenAddress);
        let module = await ForcedTransferTokenModule.at(moduleAddress);
        await module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        let result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xaf', 'Transfer is not forced');

        await module.revokeForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: owner});
        result = await token.canTransfer.call(trancheUnrestricted, operator1, investor1, investor3, 500, dataUserTransfer);
        assert.equal(result[0], '0xa6', 'Forced transfer was not revoked');
    });


    it('only token owner can force a transfer', async() => {
        let module = await ForcedTransferTokenModule.at(moduleAddress);
        await truffleAssert.reverts(module.approveForcedTransfer(trancheUnrestricted, trancheUnrestricted, operator1, investor1, investor3, 500, {from: operator2}));
    });
});