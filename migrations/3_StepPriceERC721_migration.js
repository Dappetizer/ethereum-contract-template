const StepPriceERC721 = artifacts.require("StepPriceERC721");

module.exports = function (deployer) {
  deployer.deploy(StepPriceERC721, "Step Tokens", "STEP", 100);
};
