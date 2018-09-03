const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

contract('StandardWhitelistFactory', async(accounts) => {
    it('setting and checking boolean properties work', async () => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance('wl1', {from: accounts[0]});
        let whitelistAddress = await factory.getInstance.call('wl1');
        let whitelist = await StandardWhitelist.at(whitelistAddress);
        await whitelist.setBooleanProperty(accounts[1], 'kyc', true, {from: accounts[0]});
        let result = await whitelist.checkPropertyTrue.call(accounts[1], 'kyc');
        console.log('*** RESULT ***');
        console.log(result);
        assert.equal(result.valueOf(), true, 'boolean property was not set correctly');
    });
});