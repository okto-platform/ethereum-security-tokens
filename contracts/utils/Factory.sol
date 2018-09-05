pragma solidity ^0.4.24;

contract Factory {
    address[] instances;

    event InstanceCreated(address contractAddress);

    // You should define a public `createInstance()` method in contracts inheriting
    // from this one. The reason why it is not declared here is because the parameters
    // could be different for each case

    function addInstance(address instance)
    internal
    {
        instances.push(instance);
        emit InstanceCreated(instance);
    }
}
