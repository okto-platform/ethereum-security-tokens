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
    });
});