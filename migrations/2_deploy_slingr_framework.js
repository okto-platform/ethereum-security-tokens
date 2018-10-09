var SlingrSecurityTokenFactory = artifacts.require("SlingrSecurityTokenFactory");
var KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
var ReissuanceModuleFactory = artifacts.require("ReissuanceModuleFactory");
var ExternalTokenOfferingFactory = artifacts.require("ExternalTokenOfferingFactory");
var TokensHardCapModuleFactory = artifacts.require("TokensHardCapModuleFactory");
var KycOfferingModuleFactory = artifacts.require("KycOfferingModuleFactory");
var StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
var MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

var ModularSecurityTokenFactory = artifacts.require("ModularSecurityTokenFactory");
var ModularSecurityToken = artifacts.require("ModularSecurityToken");
var ModularERC20Lib = artifacts.require("ModularERC20Lib");
var ModularERC777Lib = artifacts.require("ModularERC777Lib");
var ModularERC1410Lib = artifacts.require("ModularERC1410Lib");
var ModularERC1411Lib = artifacts.require("ModularERC1411Lib");


module.exports = function(deployer) {
  deployer.deploy(SlingrSecurityTokenFactory);
  deployer.deploy(KycTokenModuleFactory);
  deployer.deploy(ReissuanceModuleFactory);
  deployer.deploy(ExternalTokenOfferingFactory);
  deployer.deploy(TokensHardCapModuleFactory);
  deployer.deploy(KycOfferingModuleFactory);
  deployer.deploy(StandardWhitelistFactory);
  deployer.deploy(MultiSigWalletFactory);

  deployer.deploy(ModularERC1411Lib);
  deployer.link(ModularERC1411Lib, ModularERC1410Lib);
  deployer.deploy(ModularERC1410Lib);
  deployer.link(ModularERC1410Lib, ModularERC777Lib);
  deployer.deploy(ModularERC777Lib);
  deployer.link(ModularERC777Lib, ModularERC20Lib);
  deployer.deploy(ModularERC20Lib);
  deployer.link(ModularERC20Lib, ModularSecurityToken);
  deployer.link(ModularERC777Lib, ModularSecurityToken);
  deployer.link(ModularERC1410Lib, ModularSecurityToken);
  deployer.link(ModularERC1411Lib, ModularSecurityToken);
  deployer.deploy(ModularSecurityTokenFactory);
};
