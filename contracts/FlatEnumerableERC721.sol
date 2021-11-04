// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Flat Price Enumerable ERC721 Token Contract
contract FlatEnumerableERC721 is Ownable, Pausable, ERC721Enumerable {

    uint256 public maxSupply;
    uint256 public price;
    uint256 public mintCount;
    string public baseURI;

    /// @dev reverts if any tokens have been minted
    modifier onlyPreMint() {
        require(mintCount == 0, "must be before first mint");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, uint256 price_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        price = price_;

        //start in paused state
        _pause();
    }

    /// @dev toggles paused state on/off
    function togglePaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// @dev sets a new basePrice value
    /// @param newPrice value of new basePrice
    function setPrice(uint256 newPrice) public onlyOwner onlyPreMint {
        price = newPrice;
    }

    /// @dev overridden ERC721Metadata function to return baseURI
    /// @return baseURI string
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev sets a new baseURI for contract
    /// @param newBaseURI new baseURI to set
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /// @dev mints the next tokenId if min value is paid
    function mint(address to) public payable whenNotPaused {
        //validate
        require(to != address(0x0), "cannot mint to zero address");
        require(msg.value == price, "must send exact value to mint");

        //update state
        mintCount += 1;

        //send native to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "failed to send to owner address");

        //safely mint to recipient address
        _safeMint(to, mintCount);
    }

}