const SlingrSecurityTokenFactory = artifacts.require("SlingrSecurityTokenFactory");
const KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
const ReissuanceModuleFactory = artifacts.require("ReissuanceModuleFactory");
const ExternalTokenOfferingFactory = artifacts.require("ExternalTokenOfferingFactory");
const TokensHardCapModuleFactory = artifacts.require("TokensHardCapModuleFactory");
const KycOfferingModuleFactory = artifacts.require("KycOfferingModuleFactory");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");

const AddressArrayLib = artifacts.require("AddressArrayLib");
const AddressArrayLibTest = artifacts.require("AddressArrayLibTest");
const Bytes32ArrayLib = artifacts.require("Bytes32ArrayLib");
const Bytes32ArrayLibTest = artifacts.require("Bytes32ArrayLibTest");


module.exports = function(deployer) {
  deployer.deploy(SlingrSecurityTokenFactory);
  deployer.deploy(KycTokenModuleFactory);
  deployer.deploy(ReissuanceModuleFactory);
  deployer.deploy(ExternalTokenOfferingFactory);
  deployer.deploy(TokensHardCapModuleFactory);
  deployer.deploy(KycOfferingModuleFactory);
  deployer.deploy(StandardWhitelistFactory);
  deployer.deploy(MultiSigWalletFactory);

  deployer.deploy(AddressArrayLib);
  deployer.link(AddressArrayLib, AddressArrayLibTest);
  deployer.deploy(AddressArrayLibTest);

  deployer.deploy(Bytes32ArrayLib);
  deployer.link(Bytes32ArrayLib, Bytes32ArrayLibTest);
  deployer.deploy(Bytes32ArrayLibTest);

  deployer.link(Bytes32ArrayLib, SecurityTokenFactory);
  deployer.deploy(SecurityTokenFactory);
};
