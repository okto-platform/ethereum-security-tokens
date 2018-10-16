const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
const KycTokenModule = artifacts.require("KycTokenModule");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('KycTokenModuleFactory', async(accounts) => {
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

    let trancheUnrestricted = padBytes32(web3.fromUtf8('unrestricted'));
    let trancheLocked = padBytes32(web3.fromUtf8('locked'));

    let dataIssuing = padBytes32(web3.fromUtf8('issuing'));
    let dataUserTransfer = padBytes32(web3.fromUtf8('userTransfer'));
    let dataOperatorTransfer = padBytes32(web3.fromUtf8('operatorTransfer'));

    let propKyc         = '0x01';
    let propCountry     = '0x02';
    let propExpiration  = '0x03';


    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let whitelistFactory = await StandardWhitelistFactory.deployed();
        await whitelistFactory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await whitelistFactory.getInstancesCount.call();
        whitelistAddress = await whitelistFactory.getInstance.call(whitelistsCount - 1);

        let moduleFactory = await KycTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, whitelistAddress, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await whitelistFactory.getInstance.call(modulesCount - 1);

        let token = SecurityToken.at(tokenAddress);
        await token.release({from: owner});
    });


    it('only allow issuance to whitelisted investors', async() => {
        let whitelist = StandardWhitelist.at(whitelistAddress);
        await whitelist.setBool(investor1, propKyc, true, {from: validator});
        await whitelist.setBool(investor2, propKyc, true, {from: validator});

        let token = SecurityToken.at(tokenAddress);
        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheLocked, investor1, 1500, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheLocked, investor2, 500, dataIssuing, {from: operator1});

        let balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor1);
        assert.equal(balance.valueOf(), 1000, 'Incorrect balance');
        balance = await token.balanceOfByTranche.call(trancheLocked, investor1);
        assert.equal(balance.valueOf(), 1500, 'Incorrect balance');
        balance = await token.balanceOfByTranche.call(trancheUnrestricted, investor2);
        assert.equal(balance.valueOf(), 2000, 'Incorrect balance');
        balance = await token.balanceOfByTranche.call(trancheLocked, investor2);
        assert.equal(balance.valueOf(), 500, 'Incorrect balance');
    });


    it('cannot issue tokens for unknown investors', async() => {
        let token = SecurityToken.at(tokenAddress);

        await truffleAssert.reverts(token.issueByTranche(trancheUnrestricted, investor3, 1000, dataIssuing, {from: operator1}));
    });


    it('cannot transfer tokens to unknown investors', async() => {
        let token = SecurityToken.at(tokenAddress);

        await truffleAssert.reverts(token.sendByTranche(trancheUnrestricted, investor3, 1000, dataIssuing, {from: investor1}));
    });
});