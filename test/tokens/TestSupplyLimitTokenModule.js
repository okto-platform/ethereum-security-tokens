const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");
const SupplyLimitTokenModuleFactory = artifacts.require("SupplyLimitTokenModuleFactory");
const SupplyLimitTokenModule = artifacts.require("SupplyLimitTokenModule");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('SupplyLimitTokenModuleFactory', async(accounts) => {
    let tokenAddress;
    let moduleAddress;

    let owner = accounts[0];
    let operator1 = accounts[1];
    let operator2 = accounts[2];
    let investor1 = accounts[3];
    let investor2 = accounts[4];
    let investor3 = accounts[5];

    let trancheUnrestricted = padBytes32(web3.utils.fromUtf8('unrestricted'));
    let trancheLocked = padBytes32(web3.utils.fromUtf8('locked'));

    let dataIssuing = padBytes32(web3.utils.fromUtf8('issuing'));
    let dataUserTransfer = padBytes32(web3.utils.fromUtf8('userTransfer'));


    it('configure module', async() => {
        let tokenFactory = await SecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);

        let moduleFactory = await SupplyLimitTokenModuleFactory.deployed();
        await moduleFactory.createInstance(tokenAddress, 5000, {from: owner});
        let modulesCount = await moduleFactory.getInstancesCount.call();
        moduleAddress = await moduleFactory.getInstance.call(modulesCount - 1);

        let token = await SecurityToken.at(tokenAddress);
        await token.release({from: owner});
    });


    it('do not allow to exceed supply limit', async() => {
        let token = await SecurityToken.at(tokenAddress);

        await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor3, 2000, dataIssuing, {from: operator1});

        await truffleAssert.reverts(token.issueByTranche(trancheUnrestricted, investor3, 1, dataIssuing, {from: operator1}));
    });


    it('redeem tokens and issue again', async() => {
        let token = await SecurityToken.at(tokenAddress);
        await token.burnByTranche(trancheUnrestricted, investor1, 1000, dataUserTransfer, {from: operator1});
        await token.issueByTranche(trancheUnrestricted, investor3, 1000, dataIssuing, {from: operator1});
    });


    it('allow to transfer tokens when we are in the limit of supply', async() => {
        let token = await SecurityToken.at(tokenAddress);
        await token.transferByTranche(trancheUnrestricted, investor1, 1000, dataUserTransfer, {from: investor3});
    });
});