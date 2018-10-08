var SlingrSecurityTokenFactory = artifacts.require("SlingrSecurityTokenFactory");
var KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
var ReissuanceModuleFactory = artifacts.require("ReissuanceModuleFactory");
var ExternalTokenOfferingFactory = artifacts.require("ExternalTokenOfferingFactory");
var TokensHardCapModuleFactory = artifacts.require("TokensHardCapModuleFactory");
var KycOfferingModuleFactory = artifacts.require("KycOfferingModuleFactory");
var StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
var MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

var ModularSecurityTokenFactory = artifacts.require("ModularSecurityTokenFactory");


module.exports = function(deployer) {
  deployer.deploy(SlingrSecurityTokenFactory);
  deployer.deploy(KycTokenModuleFactory);
  deployer.deploy(ReissuanceModuleFactory);
  deployer.deploy(ExternalTokenOfferingFactory);
  deployer.deploy(TokensHardCapModuleFactory);
  deployer.deploy(KycOfferingModuleFactory);
  deployer.deploy(StandardWhitelistFactory);
  deployer.deploy(MultiSigWalletFactory);

  deployer.deploy(ModularSecurityTokenFactory);
};
