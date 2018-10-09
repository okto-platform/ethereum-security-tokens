const ModularSecurityTokenFactory = artifacts.require("ModularSecurityTokenFactory");
const ModularSecurityToken = artifacts.require("ModularSecurityToken");

let checkEvent = function(result, eventName) {
    for (let i = 0; i < result.logs.length; i++) {
        let log = result.logs[i];
        if (log.event == eventName) {
            return true;
        }
    }
    return false;
};

contract('ModularSecurityTokenFactory', async(accounts) => {
    it('configure simple token', async() => {
        let factory = await ModularSecurityTokenFactory.deployed();
        await factory.createInstance('Token A', 'TOKA', 18, 1, [accounts[0]], {from: accounts[0]});
        let tokensCount = await factory.getInstancesCount.call();
        let tokenAddress = await factory.getInstance.call(tokensCount - 1);
        let token = await ModularSecurityToken.at(tokenAddress);

        let name = await token.name.call();
        let symbol = await token.symbol.call();
        let decimals = await token.decimals.call();
        let granularity = await token.granularity.call();
        let totalSupply = await token.totalSupply.call();
        let issuable = await token.issuable.call();
        let status = await token.status.call();
        assert.equal(name, 'Token A', 'Token name not set');
        assert.equal(symbol, 'TOKA', 'Token symbol not set');
        assert.equal(decimals, 18, 'Token decimals not set');
        assert.equal(granularity, 1, 'Token decimals not set');
        assert.equal(totalSupply, 0, 'Token total supply is not set to zero at creation time');
        assert.equal(issuable, true, 'Token is not issuable when it is created');
        assert.equal(status, 0, 'Token is not in draft status after created');
    });

    it('configure simple token', async() => {
        let factory = await ModularSecurityTokenFactory.deployed();
        await factory.createInstance('Token B', 'TOKB', 18, 1, [accounts[0]], {from: accounts[0]});
        let tokensCount = await factory.getInstancesCount.call();
        let tokenAddress = await factory.getInstance.call(tokensCount - 1);
        let token = await ModularSecurityToken.at(tokenAddress);

        let symbol = await token.symbol.call();
        assert.equal(symbol, 'TOKB', 'Token symbol not set');
    });
});