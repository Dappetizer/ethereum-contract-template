// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract TemplateERC721 is Ownable, ERC721, ERC721Burnable {

    uint256 public tokenCount;
    uint256 public basePrice = 1000000000000000000; //1 ETH
    string public baseURI;

    constructor() ERC721("Test Tokens", "TEST") {}

    function mint(address to, uint256 tokenId) public payable {
        //validate
        require(msg.value >= basePrice, "insufficient value to mint");

        //send eth to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send");

        _safeMint(to, tokenId);

        tokenCount += 1;
    }

    // function mint(address to, uint256 tokenId, bytes memory data) public onlyOwner {
    //     _safeMint(to, tokenId, data);
    // }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /// @dev overridden ERC721Metadata function to return baseURI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    //     require(false, "in _beforeTokenTransfer()");
    // }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}