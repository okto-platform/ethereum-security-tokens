const truffleAssert = require('truffle-assertions');

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const SecurityToken = artifacts.require("SecurityToken");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

contract('SecurityTokenFactory', async(accounts) => {
    let tokenAddress;

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

    it('create token', async() => {
        let factory = await SecurityTokenFactory.deployed();
        await factory.createInstance('Token A', 'TOKA', 18, [owner, operator1, operator2], {from: owner});
        let tokensCount = await factory.getInstancesCount.call();
        tokenAddress = await factory.getInstance.call(tokensCount - 1);
        let token = await SecurityToken.at(tokenAddress);

        let name = await token.name.call();
        let symbol = await token.symbol.call();
        let decimals = await token.decimals.call();
        let totalSupply = await token.totalSupply.call();
        let released = await token.released.call();
        assert.equal(name, 'Token A', 'Token name not set');
        assert.equal(symbol, 'TOKA', 'Token symbol not set');
        assert.equal(decimals, 18, 'Token decimals not set');
        assert.equal(totalSupply, 0, 'Token total supply is not set to zero at creation time');
        assert.equal(released, false, 'Token is not in draft status after created');
    });


    it('configure token', async() => {
        let token = await SecurityToken.at(tokenAddress);
        let result = await token.release({from: owner});
        truffleAssert.eventEmitted(result, 'Released');

        let released = await token.released.call();
        assert.equal(released, true, 'Token is not released');
    });


    it('issue tokens', async() => {
        let token = await SecurityToken.at(tokenAddress);
        let result = await token.issueByTranche(trancheUnrestricted, investor1, 1000, dataIssuing, {from: operator1});
        truffleAssert.eventEmitted(result, 'IssuedByTranche');
        result = await token.issueByTranche(trancheLocked, investor1, 1000, dataIssuing, {from: operator1});
        truffleAssert.eventEmitted(result, 'IssuedByTranche');
        result = await token.issueByTranche(trancheUnrestricted, investor2, 2000, dataIssuing, {from: operator2});
        truffleAssert.eventEmitted(result, 'IssuedByTranche');
        result = await token.issueByTranche(trancheLocked, investor2, 1000, dataIssuing, {from: operator2});
        truffleAssert.eventEmitted(result, 'IssuedByTranche');

        let globalBalance = await token.balanceOf.call(investor1);
        let unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor1);
        let lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor1);
        assert.equal(globalBalance.valueOf(), 2000, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 1000, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 1000, 'Locked balance does not match');

        globalBalance = await token.balanceOf.call(investor2);
        unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor2);
        lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor2);
        assert.equal(globalBalance.valueOf(), 3000, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 2000, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 1000, 'Locked balance does not match');
    });


    it('investor transfer tokens', async() => {
        let token = await SecurityToken.at(tokenAddress);
        let result = await token.transferByTranche(trancheUnrestricted, investor3, 200, dataUserTransfer, {from: investor1});
        truffleAssert.eventEmitted(result, 'TransferByTranche');
        truffleAssert.eventEmitted(result, 'Transfer');

        let globalBalance = await token.balanceOf.call(investor1);
        let unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor1);
        let lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor1);
        assert.equal(globalBalance.valueOf(), 1800, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 800, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 1000, 'Locked balance does not match');

        globalBalance = await token.balanceOf.call(investor3);
        unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor3);
        lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor3);
        assert.equal(globalBalance.valueOf(), 200, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 200, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 0, 'Locked balance does not match');
    });


    it('operator transfer tokens', async() => {
        let token = await SecurityToken.at(tokenAddress);
        let result = await token.operatorTransferByTranche(trancheLocked, investor2, investor3, 500, dataUserTransfer, {from: operator1});
        truffleAssert.eventEmitted(result, 'TransferByTranche');
        truffleAssert.eventEmitted(result, 'Transfer');

        let globalBalance = await token.balanceOf.call(investor2);
        let unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor2);
        let lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor2);
        assert.equal(globalBalance.valueOf(), 2500, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 2000, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 500, 'Locked balance does not match');

        globalBalance = await token.balanceOf.call(investor3);
        unrestrictedBalance = await token.balanceOfByTranche.call(trancheUnrestricted, investor3);
        lockedBalance = await token.balanceOfByTranche.call(trancheLocked, investor3);
        assert.equal(globalBalance.valueOf(), 700, 'Global balance does not match');
        assert.equal(unrestrictedBalance.valueOf(), 200, 'Unrestricted balance does not match');
        assert.equal(lockedBalance.valueOf(), 500, 'Locked balance does not match');
    });


    it('tranches management', async() => {
        let token = await SecurityToken.at(tokenAddress);

        let tranches = await token.tranchesOf.call(investor1);
        assert.include(tranches, trancheUnrestricted, 'Unrestricted tranche not found');
        assert.include(tranches, trancheLocked, 'Locked tranche not found');

        tranches = await token.tranchesOf.call(investor2);
        assert.include(tranches, trancheUnrestricted, 'Unrestricted tranche not found');
        assert.include(tranches, trancheLocked, 'Locked tranche not found');

        tranches = await token.tranchesOf.call(investor3);
        assert.include(tranches, trancheUnrestricted, 'Unrestricted tranche not found');
        assert.include(tranches, trancheLocked, 'Locked tranche not found');

        // check that tranche is remove after it goes to zero
        let result = await token.operatorTransferByTranche(trancheLocked, investor2, investor3, 500, dataUserTransfer, {from: operator1});
        truffleAssert.eventEmitted(result, 'TransferByTranche');
        truffleAssert.eventEmitted(result, 'Transfer');
        tranches = await token.tranchesOf.call(investor2);
        assert.equal(tranches.length, 1, 'Tranche was not removed when it was zero');
        assert.include(tranches, trancheUnrestricted, 'Unrestricted tranche not found');
    });
});