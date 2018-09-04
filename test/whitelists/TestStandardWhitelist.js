const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");


contract('StandardWhitelistFactory', async(accounts) => {
    // TODO once truffle fixes problem with overloaded functions we can uncomment these tests
    // TODO for now if you want to test you need to change the name of functions in the contract

    /*
    it('setting and checking string properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance('wl1', {from: accounts[0]});
        let whitelistAddress = await factory.getInstance.call('wl1');
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setPropertyS(accounts[1], 'country', 'US', {from: accounts[0]});
        let result = await whitelist.checkPropertyEqualsS.call(accounts[1], 'country', 'US');
        assert.equal(result.valueOf(), true, 'string property was not set correctly');

        result = await whitelist.checkPropertyEqualsS.call(accounts[1], 'country', 'AR');
        assert.equal(result.valueOf(), false, 'string property was not set correctly');

        result = await whitelist.checkPropertyEqualsS.call(accounts[5], 'country', 'AR');
        assert.equal(result.valueOf(), false, 'string property was not set correctly');

        result = await whitelist.checkPropertyNotEqualsS.call(accounts[1], 'country', 'AR');
        assert.equal(result.valueOf(), true, 'string property was not set correctly');
    });

    it('setting and checking boolean properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance('wl2', {from: accounts[0]});
        let whitelistAddress = await factory.getInstance.call('wl2');
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setPropertyB(accounts[1], 'kyc', true, {from: accounts[0]});
        let result = await whitelist.checkPropertyTrue.call(accounts[1], 'kyc');
        assert.equal(result.valueOf(), true, 'boolean property was not set correctly');

        await whitelist.setPropertyB(accounts[2], 'kyc', false, {from: accounts[0]});
        result = await whitelist.checkPropertyTrue.call(accounts[2], 'kyc');
        assert.equal(result.valueOf(), false, 'boolean property was not set correctly');

        result = await whitelist.checkPropertyFalse.call(accounts[2], 'kyc');
        assert.equal(result.valueOf(), true, 'boolean property was not set correctly');
    });

    it('setting and checking number properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance('wl3', {from: accounts[0]});
        let whitelistAddress = await factory.getInstance.call('wl3');
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setPropertyN(accounts[1], 'expiration', 100, {from: accounts[0]});
        let result = await whitelist.checkPropertyEquals.call(accounts[1], 'expiration', 100);
        assert.equal(result.valueOf(), true, 'number property was not set correctly');

        result = await whitelist.checkPropertyNotEquals.call(accounts[1], 'expiration', 101);
        assert.equal(result.valueOf(), true, 'number property was not set correctly');

        result = await whitelist.checkPropertyNotEquals.call(accounts[1], 'expiration', 100);
        assert.equal(result.valueOf(), false, 'number property was not set correctly');

        result = await whitelist.checkPropertyGreater.call(accounts[1], 'expiration', 90);
        assert.equal(result.valueOf(), true, 'number property was not set correctly');

        result = await whitelist.checkPropertyLess.call(accounts[1], 'expiration', 110);
        assert.equal(result.valueOf(), true, 'number property was not set correctly');
    });
    */
});