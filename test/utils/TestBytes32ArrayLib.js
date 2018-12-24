const Bytes32ArrayLibTest = artifacts.require("Bytes32ArrayLibTest");

contract('Bytes32ArrayLibTest', async(accounts) => {
    let owner = accounts[0];
    let bytes = [
        web3.utils.fromUtf8('value1')+'0000000000000000000000000000000000000000000000000000',
        web3.utils.fromUtf8('value2')+'0000000000000000000000000000000000000000000000000000',
        web3.utils.fromUtf8('value3')+'0000000000000000000000000000000000000000000000000000',
        web3.utils.fromUtf8('value4')+'0000000000000000000000000000000000000000000000000000',
        web3.utils.fromUtf8('value5')+'0000000000000000000000000000000000000000000000000000',
        web3.utils.fromUtf8('value6')+'0000000000000000000000000000000000000000000000000000'
    ];

    it('add elements', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        await array.add(bytes[1], {from: owner});
        let values = await array.getArray.call();
        assert.equal(values.length, 1, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Value not added');

        await array.add(bytes[2], {from: owner});
        values = await array.getArray.call();
        assert.equal(values.length, 2, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Value not added at 0');
        assert.equal(values[1], bytes[2], 'Value not added at 1');

        await array.addIfNotPresent(bytes[2], {from: owner});
        values = await array.getArray.call();
        assert.equal(values.length, 2, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Value not added at 0');
        assert.equal(values[1], bytes[2], 'Value not added at 1');
    });


    it('find elements', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        let index = await array.indexOf.call(bytes[1]);
        assert.equal(index, 0, 'Invalid index');
        index = await array.indexOf.call(bytes[2]);
        assert.equal(index, 1, 'Invalid index');
        index = await array.indexOf.call(bytes[3]);
        assert.equal(index, -1, 'Invalid index');

        let found = await array.contains.call(bytes[1]);
        assert.isTrue(found, 'Element not found');
        found = await array.contains.call(bytes[2]);
        assert.isTrue(found, 'Element not found');
        found = await array.contains.call(bytes[3]);
        assert.isFalse(found, 'Element found when it does not exist');
    });


    it('insert elements', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        await array.insert(bytes[3], 0);
        let values = await array.getArray.call();
        assert.equal(values.length, 3, 'Invalid length');
        assert.equal(values[0], bytes[3], 'Invalid position for 0');
        assert.equal(values[1], bytes[1], 'Invalid position for 1');
        assert.equal(values[2], bytes[2], 'Invalid position for 2');


        await array.insert(bytes[4], 3);
        values = await array.getArray.call();
        assert.equal(values.length, 4, 'Invalid length');
        assert.equal(values[0], bytes[3], 'Invalid position for 0');
        assert.equal(values[1], bytes[1], 'Invalid position for 1');
        assert.equal(values[2], bytes[2], 'Invalid position for 2');
        assert.equal(values[3], bytes[4], 'Invalid position for 3');

        await array.insert(bytes[5], 3);
        values = await array.getArray.call();
        assert.equal(values.length, 5, 'Invalid length');
        assert.equal(values[0], bytes[3], 'Invalid position for 0');
        assert.equal(values[1], bytes[1], 'Invalid position for 1');
        assert.equal(values[2], bytes[2], 'Invalid position for 2');
        assert.equal(values[3], bytes[5], 'Invalid position for 3');
        assert.equal(values[4], bytes[4], 'Invalid position for 4');
    });


    it('remove elements by index', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        await array.removeAtIndex(0);
        let values = await array.getArray.call();
        assert.equal(values.length, 4, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Invalid position for 0');
        assert.equal(values[1], bytes[2], 'Invalid position for 1');
        assert.equal(values[2], bytes[5], 'Invalid position for 2');
        assert.equal(values[3], bytes[4], 'Invalid position for 3');

        await array.removeAtIndex(3);
        values = await array.getArray.call();
        assert.equal(values.length, 3, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Invalid position for 0');
        assert.equal(values[1], bytes[2], 'Invalid position for 1');
        assert.equal(values[2], bytes[5], 'Invalid position for 2');

        await array.removeAtIndex(1);
        values = await array.getArray.call();
        assert.equal(values.length, 2, 'Invalid length');
        assert.equal(values[0], bytes[1], 'Invalid position for 0');
        assert.equal(values[1], bytes[5], 'Invalid position for 1');

        await array.removeAtIndex(2);
    });


    it('remove elements by value', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        await array.removeValue(bytes[1]);
        let values = await array.getArray.call();
        assert.equal(values.length, 1, 'Invalid length');
        assert.equal(values['0'], bytes[5], 'Invalid position for 0');

        await array.removeValue(bytes[5]);
        values = await array.getArray.call();
        assert.equal(values.length, 0, 'Invalid length');
    });


    it('insert values in empty array', async() => {
        let array = await Bytes32ArrayLibTest.deployed();

        await array.insert(bytes[3], 0);
        let values = await array.getArray.call();
        assert.equal(values.length, 1, 'Invalid length');
        assert.equal(values[0], bytes[3], 'Invalid position for 0');


        await array.insert(bytes[4], 0);
        values = await array.getArray.call();
        assert.equal(values.length, 2, 'Invalid length');
        assert.equal(values[0], bytes[4], 'Invalid position for 0');
        assert.equal(values[1], bytes[3], 'Invalid position for 1');
    });
});