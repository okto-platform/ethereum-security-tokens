const SlingrSecurityTokenFactory = artifacts.require("SlingrSecurityTokenFactory");
const SlingrSecurityToken = artifacts.require("SlingrSecurityToken");
const ExternalTokenOfferingFactory = artifacts.require("ExternalTokenOfferingFactory");
const ExternalTokenOffering = artifacts.require("ExternalTokenOffering");

let checkEvent = function(result, eventName) {
    for (let i = 0; i < result.logs.length; i++) {
        let log = result.logs[i];
        if (log.event == eventName) {
            return true;
        }
    }
    return false;
};

contract('SlingrSecurityTokenFactory', async(accounts) => {
    it('configure simple token', async() => {
        let factory = await SlingrSecurityTokenFactory.deployed();
        await factory.createInstance('Token A', 'TOKA', 18, {from: accounts[0]});
        let tokensCount = await factory.getInstancesCount.call();
        let tokenAddress = await factory.getInstance.call(tokensCount - 1);
        let token = await SlingrSecurityToken.at(tokenAddress);

        let name = await token.name.call();
        let symbol = await token.symbol.call();
        let decimals = await token.decimals.call();
        assert.equal(name, 'Token A', 'Token name not set');
        assert.equal(symbol, 'TOKA', 'Token symbol not set');
        assert.equal(decimals, 18, 'Token decimals not set');
    });

    it('mint some tokens through token offering', async() => {
        let tokenFactory = await SlingrSecurityTokenFactory.deployed();
        await tokenFactory.createInstance('Token A', 'TOKA', 18, {from: accounts[0]});
        let tokensCount = await tokenFactory.getInstancesCount.call();
        let tokenAddress = await tokenFactory.getInstance.call(tokensCount - 1);
        let token = await SlingrSecurityToken.at(tokenAddress);

        let offeringFactory = await ExternalTokenOfferingFactory.deployed();
        await offeringFactory.createInstance(tokenAddress, {from: accounts[0]});
        let offeringsCount = await offeringFactory.getInstancesCount.call();
        let offeringAddress = await offeringFactory.getInstance.call(offeringsCount - 1);
        let offering = await ExternalTokenOffering.at(offeringAddress);

        await token.setTokenOffering(offeringAddress, {from: accounts[0]});
        await token.release({from: accounts[0]});
        await offering.start({from: accounts[0]});

        let result = await offering.allocateSoldTokens(accounts[1], 1000000, {from: accounts[0]});
        checkEvent(result, 'TokensMinted');

        let balance = await token.balanceOf.call(accounts[1]);
        assert.equal(balance, 1000000, 'Balance is not correct');

        result = await offering.allocateSoldTokens(accounts[2], 500000, {from: accounts[0]});
        checkEvent(result, 'TokensMinted');

        balance = await token.balanceOf.call(accounts[2]);
        assert.equal(balance, 500000, 'Balance is not correct');

        let totalTokensAllocated = await offering.totalAllocatedTokens.call();
        assert.equal(totalTokensAllocated, 1500000, 'Total allocated tokens is not correct');

        result = await offering.allocateManySoldTokens([accounts[3], accounts[4]], [100000, 200000], {from: accounts[0]});
        checkEvent(result, 'TokensMinted');

        totalTokensAllocated = await offering.totalAllocatedTokens();
        assert.equal(totalTokensAllocated, 1800000, 'Total allocated tokens is not correct');
        balance = await token.balanceOf.call(accounts[3]);
        assert.equal(balance, 100000, 'Balance is not correct');
        balance = await token.balanceOf.call(accounts[4]);
        assert.equal(balance, 200000, 'Balance is not correct');
    });
});