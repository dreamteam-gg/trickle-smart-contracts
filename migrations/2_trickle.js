const Trickle = artifacts.require("Trickle");

module.exports = function(deployer) {
  deployer.deploy(Trickle);
};
