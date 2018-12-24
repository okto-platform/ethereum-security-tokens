pragma solidity ^0.5.0;

library AddressArrayLib {
    function contains(address[] storage array, address value)
    public view returns(bool)
    {
        int index = indexOf(array, value);
        return index != -1;
    }

    function indexOf(address[] storage array, address value)
    public view returns(int)
    {
        for (int i = 0; uint(i) < array.length; i++) {
            if (array[uint(i)] == value) {
                return i;
            }
        }
        return -1;
    }

    function add(address[] storage array, address value)
    public
    {
        array.push(value);
    }

    function addIfNotPresent(address[] storage array, address value)
    public returns(bool)
    {
        if (!contains(array, value)) {
            array.push(value);
            return true;
        }
        return false;
    }

    function insert(address[] storage array, address value, uint index)
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

    function removeAtIndex(address[] storage array, uint index)
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

    function removeValue(address[] storage array, address value)
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

contract AddressArrayLibTest {
    using AddressArrayLib for address[];

    address[] internal array;

    function contains(address value)
    public view returns(bool)
    {
        return array.contains(value);
    }

    function indexOf(address value)
    public view returns(int)
    {
        return array.indexOf(value);
    }

    function add(address value)
    public
    {
        array.add(value);
    }

    function addIfNotPresent(address value)
    public returns(bool)
    {
        return array.addIfNotPresent(value);
    }

    function insert(address value, uint index)
    public
    {
        array.insert(value, index);
    }

    function removeAtIndex(uint index)
    public returns(bool)
    {
        return array.removeAtIndex(index);
    }

    function removeValue(address value)
    public returns(bool)
    {
        return array.removeValue(value);
    }

    function getArray()
    public view returns(address[] memory)
    {
        return array;
    }
}
