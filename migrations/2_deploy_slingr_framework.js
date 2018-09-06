var SlingrSecurityTokenFactory = artifacts.require("SlingrSecurityTokenFactory");
var KycModuleFactory = artifacts.require("KycModuleFactory");
var ExternalTokenOfferingFactory = artifacts.require("ExternalTokenOfferingFactory");
var TokensHardCapModuleFactory = artifacts.require("TokensHardCapModuleFactory");
var StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
var MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

module.exports = function(deployer) {
  deployer.deploy(SlingrSecurityTokenFactory);
  deployer.deploy(KycModuleFactory);
  deployer.deploy(ExternalTokenOfferingFactory);
  deployer.deploy(TokensHardCapModuleFactory);
  deployer.deploy(StandardWhitelistFactory);
  deployer.deploy(MultiSigWalletFactory);
};
