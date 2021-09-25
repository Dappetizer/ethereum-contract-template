const BuyableERC721 = artifacts.require("BuyableERC721");

module.exports = function (deployer) {
  deployer.deploy(BuyableERC721, "Test Tokens", "TEST", 100);
};
