const SecurityTokenFactory = artifacts.require("SecurityTokenFactory");
const KycTokenModuleFactory = artifacts.require("KycTokenModuleFactory");
const InvestorsLimitTokenModuleFactory = artifacts.require("InvestorsLimitTokenModuleFactory");
const SupplyLimitTokenModuleFactory = artifacts.require("SupplyLimitTokenModuleFactory");
const ForcedTransferTokenModuleFactory = artifacts.require("ForcedTransferTokenModuleFactory");
const StandardWhitelistFactory = artifacts.require("StandardWhitelistFactory");
const MultiSigWalletFactory = artifacts.require("MultiSigWalletFactory");

const AddressArrayLib = artifacts.require("AddressArrayLib");
const AddressArrayLibTest = artifacts.require("AddressArrayLibTest");
const Bytes32ArrayLib = artifacts.require("Bytes32ArrayLib");
const Bytes32ArrayLibTest = artifacts.require("Bytes32ArrayLibTest");


module.exports = function(deployer) {
  deployer.deploy(AddressArrayLib);
  deployer.link(AddressArrayLib, AddressArrayLibTest);
  deployer.deploy(AddressArrayLibTest);

  deployer.deploy(Bytes32ArrayLib);
  deployer.link(Bytes32ArrayLib, Bytes32ArrayLibTest);
  deployer.deploy(Bytes32ArrayLibTest);

  deployer.link(Bytes32ArrayLib, SecurityTokenFactory);
  deployer.link(AddressArrayLib, SecurityTokenFactory);
  deployer.deploy(SecurityTokenFactory);

  deployer.deploy(KycTokenModuleFactory);
  deployer.deploy(InvestorsLimitTokenModuleFactory);
  deployer.deploy(SupplyLimitTokenModuleFactory);
  deployer.deploy(ForcedTransferTokenModuleFactory);

  deployer.deploy(StandardWhitelistFactory);
  deployer.deploy(MultiSigWalletFactory);
};
