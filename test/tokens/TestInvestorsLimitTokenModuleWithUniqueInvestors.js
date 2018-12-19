const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");
const InvestorsLimitTokenModuleFactory = artifacts.require("InvestorsLimitTokenModuleFactory");
const InvestorsLimitTokenModule = artifacts.require("InvestorsLimitTokenModule");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('InvestorsLimitTokenModuleFactory', async(accounts) => {
    let tokenAddress;
    let whitelistAddress;
    let moduleAddress;

    let owner = accounts[0];
    let operator1 = accounts[1];
    let operator2 = accounts[2];
    let investor1 = accounts[3];
    let investor2 = accounts[4];
    let investor3a = accounts[5];
    let investor3b = accounts[6];
    let investor3c = accounts[7];
    let validator = accounts[8];

    let trancheUnrestricted = padBytes32(web3.fromUtf8('unrestricted'));
    let trancheLocked = padBytes32(web3.fromUtf8('locked'));

    let dataIssuing = padBytes32(web3.fromUtf8('issuing'));
    let dataUserTransfer = padBytes32(web3.fromUtf8('userTransfer'));

    let investorIdBucket = web3.fromUtf8('investorId');
    let investorId1 = web3.fromUtf8('investor1');
    let investorId2 = web3.fromUtf8('investor2');
    let investorId3 = web3.fromUtf8('investor3');
    let investorId4 = web3.fromUtf8('investor4');

    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let whitelistFactory = await StandardWhitelistFactory.deployed();
        await whitelistFactory.createInstance(tokenAddress, [validator], [], [], [], [], {from: owner});
        let whitelistsCount = await whitelistFactory.getInstancesCount.call();
        whitelistAddress = await whitelistFactory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await whitelist.setBucket(investor1, investorIdBucket, investorId1, {from: validator});
        await whitelist.setBucket(investor2, investorIdBucket, investorId2, {from: validator});
        await whitelist.setBucket(investor3a, investorIdBucket, investorId3, {from: validator});
        await whitelist.setBucket(investor3b, investorIdBucket, investorId3, {from: validator});
        await whitelist.setBucket(investor3c, investorIdBucket, investorId3, {from: validator});

        let moduleFactory = await InvestorsLimitTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, 2, whitelistAddress, investorIdBucket, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await moduleFactory.getInstance.call(modulesCount - 1);

        let token = SecurityToken.at(tokenAddress);
        await token.release({from: owner});
    });


    it('do not allow to exceed number of investors', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = InvestorsLimitTokenModule.at(moduleAddress);

        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        let numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 1, "Invalid number of investors");

        await token.issueByTranche(trancheUnrestricted, investor3a, 2000, dataIssuing, {from: operator1});
        numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 2, "Invalid number of investors");

        await truffleAssert.reverts(token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1}));
    });


    it('allow to issue tokens to same investor in different wallet', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = InvestorsLimitTokenModule.at(moduleAddress);
        await token.issueByTranche(trancheUnrestricted, investor3b, 2000, dataIssuing, {from: operator1});
        let numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 2, "Invalid number of investors");
    });


    it('allow to transfer tokens to same investor in different wallet', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = InvestorsLimitTokenModule.at(moduleAddress);
        await token.transferByTranche(trancheUnrestricted, investor3c, 1000, dataUserTransfer, {from: investor3a});
        let numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 2, "Invalid number of investors");
    });


    it('do not allow to change investor id in whitelist exceeding limit', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = InvestorsLimitTokenModule.at(moduleAddress);
        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await truffleAssert.reverts(whitelist.setBucket(investor3c, investorIdBucket, investorId4, {from: validator}));
        let numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 2, "Invalid number of investors");
    });


    it('decrease number of investors when wallets are merged in one investor', async() => {
        let token = SecurityToken.at(tokenAddress);
        let module = InvestorsLimitTokenModule.at(moduleAddress);
        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await whitelist.setBucket(investor1, investorIdBucket, investorId3, {from: validator});
        let numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 1, "Invalid number of investors");
    });
});