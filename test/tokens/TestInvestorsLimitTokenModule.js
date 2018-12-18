const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const InvestorsLimitTokenModuleFactory = artifacts.require("InvestorsLimitTokenModuleFactory");
const InvestorsLimitTokenModule = artifacts.require("InvestorsLimitTokenModule");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('InvestorsLimitTokenModuleFactory', async(accounts) => {
    let tokenAddress;
    let moduleAddress;

    let owner = accounts[0];
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


    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let moduleFactory = await InvestorsLimitTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, 2, '0x0', '0x0', {from: owner});
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

        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});
        numberOfInvestors = await module.numberOfInvestors.call();
        assert.equal(numberOfInvestors.valueOf(), 2, "Invalid number of investors");

        await truffleAssert.reverts(token.issueByTranche(trancheUnrestricted, investor3, 2000, dataIssuing, {from: operator1}));
    });


    it('decrease number of investors when there are no more tokens', async() => {
        let token = SecurityToken.at(tokenAddress);
        await token.operatorRedeemByTranche(trancheUnrestricted, investor1, 1000, dataUserTransfer, dataOperatorTransfer, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor3, 1000, dataIssuing, {from: operator1});
    });


    it('allow to transfer all tokens to another investor', async() => {
        let token = SecurityToken.at(tokenAddress);
        await token.sendByTranche(trancheUnrestricted, investor1, 1000, dataUserTransfer, {from: investor3});
    });
});