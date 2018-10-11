const AddressArrayLibTest = artifacts.require("AddressArrayLibTest");

contract('AddressArrayLibTest', async(accounts) => {
    let owner = accounts[0];

    it('add elements', async() => {
        let array = await AddressArrayLibTest.deployed();

        await array.add(accounts[1], {from: owner});
        let addresses = await array.getArray.call();
        assert.equal(addresses.length, 1, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Value not added');

        await array.add(accounts[2], {from: owner});
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 2, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Value not added at 0');
        assert.equal(addresses[1], accounts[2], 'Value not added at 1');

        await array.addIfNotPresent(accounts[2], {from: owner});
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 2, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Value not added at 0');
        assert.equal(addresses[1], accounts[2], 'Value not added at 1');
    });


    it('find elements', async() => {
        let array = await AddressArrayLibTest.deployed();

        let index = await array.indexOf.call(accounts[1]);
        assert.equal(index, 0, 'Invalid index');
        index = await array.indexOf.call(accounts[2]);
        assert.equal(index, 1, 'Invalid index');
        index = await array.indexOf.call(accounts[3]);
        assert.equal(index, -1, 'Invalid index');

        let found = await array.contains.call(accounts[1]);
        assert.isTrue(found, 'Element not found');
        found = await array.contains.call(accounts[2]);
        assert.isTrue(found, 'Element not found');
        found = await array.contains.call(accounts[3]);
        assert.isFalse(found, 'Element found when it does not exist');
    });


    it('insert elements', async() => {
        let array = await AddressArrayLibTest.deployed();

        await array.insert(accounts[3], 0);
        let addresses = await array.getArray.call();
        assert.equal(addresses.length, 3, 'Invalid length');
        assert.equal(addresses[0], accounts[3], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[1], 'Invalid position for 1');
        assert.equal(addresses[2], accounts[2], 'Invalid position for 2');


        await array.insert(accounts[4], 3);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 4, 'Invalid length');
        assert.equal(addresses[0], accounts[3], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[1], 'Invalid position for 1');
        assert.equal(addresses[2], accounts[2], 'Invalid position for 2');
        assert.equal(addresses[3], accounts[4], 'Invalid position for 3');

        await array.insert(accounts[5], 3);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 5, 'Invalid length');
        assert.equal(addresses[0], accounts[3], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[1], 'Invalid position for 1');
        assert.equal(addresses[2], accounts[2], 'Invalid position for 2');
        assert.equal(addresses[3], accounts[5], 'Invalid position for 3');
        assert.equal(addresses[4], accounts[4], 'Invalid position for 4');
    });


    it('remove elements by index', async() => {
        let array = await AddressArrayLibTest.deployed();

        await array.removeAtIndex(0);
        let addresses = await array.getArray.call();
        assert.equal(addresses.length, 4, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[2], 'Invalid position for 1');
        assert.equal(addresses[2], accounts[5], 'Invalid position for 2');
        assert.equal(addresses[3], accounts[4], 'Invalid position for 3');

        await array.removeAtIndex(3);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 3, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[2], 'Invalid position for 1');
        assert.equal(addresses[2], accounts[5], 'Invalid position for 2');

        await array.removeAtIndex(1);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 2, 'Invalid length');
        assert.equal(addresses[0], accounts[1], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[5], 'Invalid position for 1');

        await array.removeAtIndex(2);
    });


    it('remove elements by value', async() => {
        let array = await AddressArrayLibTest.deployed();

        await array.removeValue(accounts[1]);
        let addresses = await array.getArray.call();
        assert.equal(addresses.length, 1, 'Invalid length');
        assert.equal(addresses['0'], accounts[5], 'Invalid position for 0');

        await array.removeValue(accounts[5]);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 0, 'Invalid length');
    });


    it('insert values in empty array', async() => {
        let array = await AddressArrayLibTest.deployed();

        await array.insert(accounts[3], 0);
        let addresses = await array.getArray.call();
        assert.equal(addresses.length, 1, 'Invalid length');
        assert.equal(addresses[0], accounts[3], 'Invalid position for 0');


        await array.insert(accounts[4], 0);
        addresses = await array.getArray.call();
        assert.equal(addresses.length, 2, 'Invalid length');
        assert.equal(addresses[0], accounts[4], 'Invalid position for 0');
        assert.equal(addresses[1], accounts[3], 'Invalid position for 1');
    });
});