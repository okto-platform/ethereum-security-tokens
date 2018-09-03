const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

contract('StandardWhitelistFactory', async(accounts) => {
    it('setting and checking boolean properties work', async () => {
        let factory = await StandardWhitelistFactory.deployed();
        let creationTx = await factory.createInstance();
        let whitelist = await StandardWhitelist.at(creationTx.contractAddress);
        await whitelist.setProperty(accounts[0], 'kyc', true);
        let result = await whitelist.checkPropertyTrue.call(accounts[0], 'kyc');
        assert.equal(result.valueOf(), true, 'boolean property was not set correctly');
    });
});