const truffleAssert = require('truffle-assertions');

const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");


contract('StandardWhitelistFactory', async(accounts) => {
    let owner = accounts[0];
    let validator = accounts[9];

    let propKyc         = '0x01';
    let propCountry     = '0x02';
    let propExpiration  = '0x03';

    it('setting and checking string properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setString(accounts[1], propCountry, 'US', {from: validator});
        await whitelist.setString(accounts[2], propCountry, 'AR', {from: validator});

        let result = await whitelist.getString.call(accounts[1], propCountry);
        assert.equal(result, 'US', 'string property was not set correctly');

        result = await whitelist.getString.call(accounts[2], propCountry);
        assert.equal(result, 'AR', 'string property was not set correctly');
    });

    it('setting and checking boolean properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setBool(accounts[1], propKyc, true, {from: validator});
        await whitelist.setBool(accounts[2], propKyc, false, {from: validator});

        let result = await whitelist.getBool.call(accounts[1], propKyc);
        assert.equal(result.valueOf(), true, 'boolean property was not set correctly');

        result = await whitelist.getBool.call(accounts[2], propKyc);
        assert.equal(result.valueOf(), false, 'boolean property was not set correctly');
    });

    it('setting and checking number properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.setNumber(accounts[1], propExpiration, 100, {from: validator});

        let result = await whitelist.getNumber.call(accounts[1], propExpiration);
        assert.equal(result.valueOf(), 100, 'number property was not set correctly');
    });


    it('only validators can set properties', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await truffleAssert.reverts(whitelist.setNumber(accounts[1], propExpiration, 100, {from: accounts[2]}));
    });


    it('only owner can add properties', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.addProperty('0x30', 3, {from: owner});
        await truffleAssert.reverts(whitelist.addProperty('0x31', 1, {from: validator}));
        await truffleAssert.reverts(whitelist.addProperty('0x01', 1, {from: owner}));
    });
});