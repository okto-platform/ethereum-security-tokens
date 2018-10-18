const AddressArrayLib = artifacts.require("AddressArrayLib");
const AddressArrayLibTest = artifacts.require("AddressArrayLibTest");
const Bytes32ArrayLib = artifacts.require("Bytes32ArrayLib");
const Bytes32ArrayLibTest = artifacts.require("Bytes32ArrayLibTest");

const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");

const KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
const InvestorsLimitTokenModuleFactory = artifacts.require("InvestorsLimitTokenModuleFactory");
const SupplyLimitTokenModuleFactory = artifacts.require("SupplyLimitTokenModuleFactory");
const ForcedTransferTokenModuleFactory = artifacts.require("ForcedTransferTokenModuleFactory");
const OfferingTokenModuleFactory = artifacts.require("OfferingTokenModuleFactory");

const WhitelistFactory = artifacts.require("WhitelistFactory");
const TypedWhitelistFactory = artifacts.require("TypedWhitelistFactory");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");

const MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

module.exports = function(deployer) {
  // Libraries

  deployer.deploy(AddressArrayLib);
  deployer.link(AddressArrayLib, AddressArrayLibTest);
  deployer.deploy(AddressArrayLibTest);

  deployer.deploy(Bytes32ArrayLib);
  deployer.link(Bytes32ArrayLib, Bytes32ArrayLibTest);
  deployer.deploy(Bytes32ArrayLibTest);

  // Security token

  deployer.link(Bytes32ArrayLib, SecurityTokenFactory);
  deployer.link(AddressArrayLib, SecurityTokenFactory);
  deployer.deploy(SecurityTokenFactory);

  // Token modules

  deployer.deploy(KycTokenModuleFactory);
  deployer.deploy(InvestorsLimitTokenModuleFactory);
  deployer.deploy(SupplyLimitTokenModuleFactory);
  deployer.deploy(ForcedTransferTokenModuleFactory);
  deployer.deploy(OfferingTokenModuleFactory);

  // Whitelists

  deployer.link(AddressArrayLib, WhitelistFactory);
  deployer.deploy(WhitelistFactory);
  deployer.link(AddressArrayLib, TypedWhitelistFactory);
  deployer.deploy(TypedWhitelistFactory);
  deployer.link(AddressArrayLib, StandardWhitelistFactory);
  deployer.deploy(StandardWhitelistFactory);

  // Wallets

  deployer.deploy(MultiSigWalletFactory);
};
