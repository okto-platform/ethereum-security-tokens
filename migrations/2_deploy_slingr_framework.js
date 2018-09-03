var StandardWhitelistFactory = artifacts.require("./StandardWhitelistFactory.sol");

module.exports = function(deployer) {
  deployer.deploy(StandardWhitelistFactory);
};
