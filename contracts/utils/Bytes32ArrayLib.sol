pragma solidity ^0.5.0;

library Bytes32ArrayLib {
    function contains(bytes32[] storage array, bytes32 value)
    public view returns(bool)
    {
        int index = indexOf(array, value);
        return index != -1;
    }

    function indexOf(bytes32[] storage array, bytes32 value)
    public view returns(int)
    {
        for (int i = 0; uint(i) < array.length; i++) {
            if (array[uint(i)] == value) {
                return i;
            }
        }
        return -1;
    }

    function add(bytes32[] storage array, bytes32 value)
    public
    {
        array.push(value);
    }

    function addIfNotPresent(bytes32[] storage array, bytes32 value)
    public returns(bool)
    {
        if (!contains(array, value)) {
            array.push(value);
            return true;
        }
        return false;
    }

    function insert(bytes32[] storage array, bytes32 value, uint index)
    public
    {
        if (index > array.length) {
            revert("Out of bounds");
        } else if (index == array.length) {
            add(array, value);
        } else {
            array.push(array[array.length - 1]);
            for (uint i = array.length - 2; i > index; i--) {
                array[i] = array[i - 1];
            }
            array[index] = value;
        }
    }

    function removeAtIndex(bytes32[] storage array, uint index)
    public returns(bool)
    {
        if (index >= array.length) {
            return false;
        }
        for (uint i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        delete array[array.length - 1];
        array.length--;
        return true;
    }

    function removeValue(bytes32[] storage array, bytes32 value)
    public returns(bool)
    {
        int index = indexOf(array, value);
        if (index >= 0) {
            return removeAtIndex(array, uint(index));
        } else {
            return false;
        }
    }
}

contract Bytes32ArrayLibTest {
    using Bytes32ArrayLib for bytes32[];

    bytes32[] internal array;

    function contains(bytes32 value)
    public view returns(bool)
    {
        return array.contains(value);
    }

    function indexOf(bytes32 value)
    public view returns(int)
    {
        return array.indexOf(value);
    }

    function add(bytes32 value)
    public
    {
        array.add(value);
    }

    function addIfNotPresent(bytes32 value)
    public returns(bool)
    {
        return array.addIfNotPresent(value);
    }

    function insert(bytes32 value, uint index)
    public
    {
        array.insert(value, index);
    }

    function removeAtIndex(uint index)
    public returns(bool)
    {
        return array.removeAtIndex(index);
    }

    function removeValue(bytes32 value)
    public returns(bool)
    {
        return array.removeValue(value);
    }

    function getArray()
    public view returns(bytes32[] memory)
    {
        return array;
    }
}
