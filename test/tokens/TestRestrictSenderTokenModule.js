const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const RestrictSenderTokenModuleFactory = artifacts.require("RestrictSenderTokenModuleFactory");
const RestrictSenderTokenModule = artifacts.require("RestrictSenderTokenModule");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('RestrictSenderTokenModuleFactory', async(accounts) => {
    let tokenAddress;
    let whitelistAddress;
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


    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let whitelistFactory = await StandardWhitelistFactory.deployed();
        await whitelistFactory.createInstance(tokenAddress, [validator], [], [], [], [], {from: owner});
        let whitelistsCount = await whitelistFactory.getInstancesCount.call();
        whitelistAddress = await whitelistFactory.getInstance.call(whitelistsCount - 1);

        let moduleFactory = await RestrictSenderTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, whitelistAddress, true, true, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await moduleFactory.getInstance.call(modulesCount - 1);

        let token = await SecurityToken.at(tokenAddress);
        await token.release({from: owner});
        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheLocked, investor1, 1500, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheLocked, investor2, 500, dataIssuing, {from: operator1});

        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await whitelist.setBucket(investor2, generalBucket, '0x0000000000000000000000000000000000100000000000000000000000000000'); // ats flag set
    });


    it('do not allow to transfer tokens to regular investor', async() => {
        let token = await SecurityToken.at(tokenAddress);

        await truffleAssert.reverts(token.transferByTranche(trancheUnrestricted, investor3, 500, dataIssuing, {from: investor1}));
    });


    it('allow to transfer tokens from operator', async() => {
        let token = await SecurityToken.at(tokenAddress);

        await token.operatorTransferByTranche(trancheUnrestricted, investor1, investor3, 500, dataUserTransfer, {from: operator1});
        let balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor1);
        assert.equal(balance.valueOf(), 500, 'Incorrect balance');
        balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor3);
        assert.equal(balance.valueOf(), 500, 'Incorrect balance');
    });


    it('allow to transfer tokens from ats', async() => {
        let token = await SecurityToken.at(tokenAddress);

        await token.transferByTranche(trancheUnrestricted, investor3, 1000, dataUserTransfer, {from: investor2});
        let balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor2);
        assert.equal(balance.valueOf(), 1000, 'Incorrect balance');
        balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor3);
        assert.equal(balance.valueOf(), 1500, 'Incorrect balance');
    });
});