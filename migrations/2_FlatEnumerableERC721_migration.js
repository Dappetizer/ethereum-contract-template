const FlatEnumerableERC721 = artifacts.require("FlatEnumerableERC721");

module.exports = function (deployer) {
  deployer.deploy(FlatEnumerableERC721, "Flat Tokens", "FLAT", 100, 25);
};
