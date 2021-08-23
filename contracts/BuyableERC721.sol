// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BuyableERC721 is Ownable, Pausable, ERC721, ERC721Burnable {

    uint256 public mintCount;
    uint256 public burnCount;
    uint256 public maxSupply;
    uint256 public basePrice = 1000000000000000000; //1 ETH
    string public baseURI;

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
    }

    /// @dev toggles paused state
    function togglePaused() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @dev mints the tokenId if min value is paid
    /// @param to address to receive the new token
    /// @param tokenId id of token to mint
    function mint(address to, uint256 tokenId) public payable {
        //validate
        require(msg.value == basePrice, "Must send exact value to mint");

        //send eth to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(to, tokenId);
    }

    /// @dev mints the tokenId and forwards data if min value is paid
    /// @param to address to receive the new token
    /// @param tokenId id of token to mint
    /// @param data extra bytes data to pass along
    function mint(address to, uint256 tokenId, bytes memory data) public payable {
        //validate
        require(msg.value == basePrice, "Must send exact value to mint");

        //send eth to owner address
        (bool sent, bytes memory data2) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(to, tokenId, data);
    }

    /// @dev sets a new basePrice value
    /// @param newBasePrice value of new basePrice
    function setBasePrice(uint256 newBasePrice) public onlyOwner {
        basePrice = newBasePrice;
    }

    /// @dev sets a new baseURI for contract
    /// @param newBaseURI new baseURI to set
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /// @dev overridden ERC721Metadata function to return baseURI
    /// @return baseURI string
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev overridden ERC721 function hook that is called before every token transfer, including
    /// minting and burning events.
    /// @param from address token is moving from
    /// @param to address token is moving to
    /// @param tokenId id of token being moved
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        //if minting
        if (from == address(0x0)) {
            mintCount += 1;
        }

        //if burning
        if (to == address(0x0)) {
            burnCount += 1;
        }
    }

    /// @dev function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @dev fallback function is called when msg.data is not empty
    fallback() external payable {}
}