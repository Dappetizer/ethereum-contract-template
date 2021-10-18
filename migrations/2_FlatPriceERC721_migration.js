const FlatPriceERC721 = artifacts.require("FlatPriceERC721");

module.exports = function (deployer) {
  deployer.deploy(FlatPriceERC721, "Flat Tokens", "FLAT", 100);
};
