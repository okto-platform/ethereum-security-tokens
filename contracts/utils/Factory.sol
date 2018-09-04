pragma solidity ^0.4.24;

contract Factory {
    mapping(string => address) instances;

    event InstanceCreated(address contractAddress, string name, address sender);

    // You should define a public `createInstance(_name)` method in contracts inheriting
    // from this one. The reason why it is not declared here is because the parameters
    // could be different for each case

    function addInstance(address instance, string _name)
    internal
    {
        instances[_name] = instance;
        emit InstanceCreated(instance, _name, msg.sender);
    }

    function checkUniqueName(string _name)
    internal
    {
        require(instances[_name] == address(0), "Name is already taken");
    }

    function getInstance(string _name)
    public view returns(address)
    {
        return instances[_name];
    }
}
