const EasyERC721 = artifacts.require("EasyERC721");
const PRICE = `${1*1e18}`; //1 ETH

module.exports = function (deployer) {
  deployer.deploy(EasyERC721, "Easy Tokens", "EASY", 100, PRICE);
};
