const truffleAssert = require('truffle-assertions');

const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const StandardWhitelist = artifacts.require("StandardWhitelist");

let padBytes32 = function(value) {
    return value.padEnd(66, '0');
};

// KYC flag                           index   0, length   1 bits
// KYC expiration timestamp           index   1, length  40 bits
// Country code (two letters code)    index  41, length  16 bits
let generalBucket      = web3.fromUtf8('general');
let propKyc            = web3.fromUtf8('kyc');
let propKycExpiration  = web3.fromUtf8('kycExpiration');
let propCountry        = web3.fromUtf8('country');
let props = {};
props[propKyc] = {from: 0, len: 1};
props[propKycExpiration] = {from: 1, len: 40};
props[propCountry] = {from: 82, len: 16};


var Bytes32 = function(initBinaryVal) {
    var self = this;

    self.IS_BYTES_32 = true;

    if (initBinaryVal) {
        if (initBinaryVal.length != 256) {
            throw 'Invalid initial value. It must be 256 long';
        }
        self.val = initBinaryVal;
    } else {
        // this represents the 256 bits
        self.val = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
    }

    var copyString = function(s) {
        return (' ' + s).slice(1);
    };

    self.or = function(another) {
        var res = '';
        for (var i = 0; i < 256; i++) {
            if (self.val[i] == '1' || another.val[i] == '1') {
                res += '1';
            } else {
                res += '0';
            }
        }
        return new Bytes32(res);
    };

    self.and = function(another) {
        var res = '';
        for (var i = 0; i < 256; i++) {
            if (self.val[i] == '1' && another.val[i] == '1') {
                res += '1';
            } else {
                res += '0';
            }
        }
        return new Bytes32(res);
    };

    self.shiftLeft = function(places) {
        var res = copyString(self.val).substr(places);
        for (var i = 0; i < places; i++) {
            res += '0';
        }
        return new Bytes32(res);
    };

    self.shiftRight = function(places) {
        var res = '';
        for (var i = 0; i < places; i++) {
            res += '0';
        }
        var s = copyString(self.val);
        res += s.substr(0, s.length - places);
        return new Bytes32(res);
    };

    self.setBits = function(index, len, value) {
        var res = copyString(self.val);
        var s = (value.IS_BYTES_32) ? value.val : value;
        res = res.substr(0, index) + s.substr(s.length - len, len) + res.substr(index + len);
        return new Bytes32(res);
    };

    self.getBits = function(index, len) {
        var newVal = self.shiftLeft(index);
        return newVal.shiftRight(256 - len);
    };

    self.toHex = function() {
        var i, k, part, accum, ret = '';
        var s = self.val;
        for (i = s.length-1; i >= 3; i -= 4) {
            // extract out in substrings of 4 and convert to hex
            part = s.substr(i+1-4, 4);
            accum = 0;
            for (k = 0; k < 4; k += 1) {
                if (part[k] !== '0' && part[k] !== '1') {
                    // invalid character
                    throw 'Invalid internal value';
                }
                // compute the length 4 substring
                accum = accum * 2 + parseInt(part[k], 10);
            }
            if (accum >= 10) {
                // 'A' to 'F'
                ret = String.fromCharCode(accum - 10 + 'A'.charCodeAt(0)) + ret;
            } else {
                // '0' to '9'
                ret = String(accum) + ret;
            }
        }
        // remaining characters, i = 0, 1, or 2
        if (i >= 0) {
            accum = 0;
            // convert from front
            for (k = 0; k <= i; k += 1) {
                if (s[k] !== '0' && s[k] !== '1') {
                    throw 'Invalid internal value';
                }
                accum = accum * 2 + parseInt(s[k], 10);
            }
            // 3 bits, value cannot exceed 2^3 - 1 = 7, just convert
            ret = String(accum) + ret;
        }
        return ret;
    };

    self.fromHex = function(s) {
        if (s && s.indexOf('0x') == 0) {
            s = s.substr(2);
        }
        if (!s || s.length > 64) {
            throw 'Invalid length';
        }
        var i, k, part, ret = '';
        // lookup table for easier conversion. '0' characters are padded for '1' to '7'
        var lookupTable = {
            '0': '0000', '1': '0001', '2': '0010', '3': '0011', '4': '0100',
            '5': '0101', '6': '0110', '7': '0111', '8': '1000', '9': '1001',
            'a': '1010', 'b': '1011', 'c': '1100', 'd': '1101',
            'e': '1110', 'f': '1111',
            'A': '1010', 'B': '1011', 'C': '1100', 'D': '1101',
            'E': '1110', 'F': '1111'
        };
        for (i = 0; i < s.length; i += 1) {
            if (lookupTable.hasOwnProperty(s[i])) {
                ret += lookupTable[s[i]];
            } else {
                throw 'Invalid hex';
            }
        }
        var pad = 256 - ret.length;
        self.val = '';
        for (var i = 0; i < pad; i++) {
            self.val += '0';
        }
        self.val += ret;
    };

    self.toNumber = function() {
        return parseInt(self.val, 2);
    };

    self.fromNumber = function(n) {
        var binary = n.toString(2);
        self.val = '';
        var pad = 256 - binary.length;
        for (var i = 0; i < pad; i++) {
            self.val += '0';
        }
        self.val += binary;
    };

    self.toStr = function() {
        var res = '';
        for (var i = 0; i < parseInt(256 / 8); i++) {
            var index = i * 8;
            var binaryChar = self.val.substr(index, 8);
            var charCode = parseInt(binaryChar, 2);
            if (charCode !== 0) {
                res += String.fromCharCode(charCode);
            }
        }
        return res;
    };

    self.fromStr = function(s) {
        var binary = '';
        for (var i = 0; i < s.length; i++) {
            var binaryChar = s.charCodeAt(i).toString(2);
            var charPad = 8 - binaryChar.length;
            for (var j = 0; j < charPad; j++) {
                binary += '0';
            }
            binary += binaryChar;
        }
        if (binary.length > 256) {
            throw 'String is too long';
        }
        var pad = 256 - binary.length;
        self.val = '';
        for (var i = 0; i < pad; i++) {
            self.val += '0';
        }
        self.val += binary;
    };

    self.toBoolean = function(b) {
        return self.toNumber() !== 0;
    };

    self.fromBoolean = function(b) {
        if (b) {
            self.val = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001';
        } else {
            self.val = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
        }
    };

    return self;
};
Bytes32.fromString = function(s) {
    var bytes32 = new Bytes32();
    bytes32.fromStr(s);
    return bytes32;
};
Bytes32.fromHex = function(hex) {
    var bytes32 = new Bytes32();
    bytes32.fromHex(hex);
    return bytes32;
};
Bytes32.fromNumber = function(n) {
    var bytes32 = new Bytes32();
    bytes32.fromNumber(n);
    return bytes32;
};
Bytes32.fromBoolean = function(b) {
    var bytes32 = new Bytes32();
    bytes32.fromBoolean(b);
    return bytes32;
};

let packProperties = function(current, prop, value) {
    if (current === null || typeof current === 'undefined') {
        current = new Bytes32();
    }
    let from = props[prop].from;
    let len = props[prop].len;
    return current.setBits(from, len, value);
};

let getProperties = function(value, prop) {
    let from = props[prop].from;
    let len = props[prop].len;
    return value.getBits(from, len);
};


contract('StandardWhitelistFactory', async(accounts) => {
    let owner = accounts[0];
    let validator = accounts[9];

    it('setting and checking string properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        let props = packProperties(null, propCountry, Bytes32.fromString('us'));
        await whitelist.setBucket(accounts[1], generalBucket, '0x'+props.toHex(), {from: validator});
        props = packProperties(null, propCountry, Bytes32.fromString('ar'));
        await whitelist.setBucket(accounts[2], generalBucket, '0x'+props.toHex(), {from: validator});


        let result = await whitelist.getBucket.call(accounts[1], generalBucket);
        result = Bytes32.fromHex(result.toString(16));
        result = getProperties(result, propCountry);
        assert.equal(result.toStr(), 'us', 'properties configurations is incorrect');

        result = await whitelist.getProperty.call(accounts[1], propCountry);
        assert.equal(Bytes32.fromHex(result.toString(16)).toStr(), 'us', 'country property was not set correctly');

        result = await whitelist.getProperty.call(accounts[2], propCountry);
        assert.equal(Bytes32.fromHex(result.toString(16)).toStr(), 'ar', 'country property was not set correctly');
    });

    it('setting and checking boolean properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        let props = packProperties(null, propKyc, Bytes32.fromBoolean(true));
        await whitelist.setBucket(accounts[1], generalBucket, '0x'+props.toHex(), {from: validator});
        props = packProperties(null, propKyc, Bytes32.fromBoolean(false));
        await whitelist.setBucket(accounts[2], generalBucket, '0x'+props.toHex(), {from: validator});

        let result = await whitelist.getProperty.call(accounts[1], propKyc);
        assert.equal(Bytes32.fromHex(result.toString(16)).toBoolean(), true, 'kyc property was not set correctly');

        result = await whitelist.getProperty.call(accounts[2], propKyc);
        assert.equal(Bytes32.fromHex(result.toString(16)).toBoolean(), false, 'kyc property was not set correctly');
    });


    it('setting and checking number properties work', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        let props = packProperties(null, propKycExpiration, Bytes32.fromNumber(100));
        await whitelist.setBucket(accounts[1], generalBucket, '0x'+props.toHex(), {from: validator});

        let result = await whitelist.getProperty.call(accounts[1], propKycExpiration);
        assert.equal(Bytes32.fromHex(result.toString(16)).toNumber(), 100, 'number property was not set correctly');
    });


    it('only validators can set properties', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        let props = packProperties(null, propKycExpiration, Bytes32.fromNumber(100));
        await truffleAssert.reverts(whitelist.setBucket(accounts[1], generalBucket, '0x'+props.toHex(), {from: accounts[2]}));
    });


    it('only owner can add properties', async() => {
        let factory = await StandardWhitelistFactory.deployed();
        await factory.createInstance([validator], [], [], [], [], {from: owner});
        let whitelistsCount = await factory.getInstancesCount.call();
        let whitelistAddress = await factory.getInstance.call(whitelistsCount - 1);
        let whitelist = await StandardWhitelist.at(whitelistAddress);

        await whitelist.addProperty('0x30', generalBucket, 90, 16, {from: owner});
        await truffleAssert.reverts(whitelist.addProperty('0x31', generalBucket, 100, 12, {from: validator}));
        await truffleAssert.reverts(whitelist.addProperty('0x30', generalBucket, 112, 4, {from: owner}));
    });
});