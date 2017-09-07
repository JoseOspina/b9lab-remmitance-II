var Remittances = artifacts.require("./Remittances.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Remittances);
};
