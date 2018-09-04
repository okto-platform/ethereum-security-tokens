var StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");

module.exports = function(deployer) {
  deployer.deploy(StandardWhitelistFactory);
};
