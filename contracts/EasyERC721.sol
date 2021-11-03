// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Easy ERC721 token implementation. Includes Metadata and Enumerable extensions.
///
contract EasyERC721 is Ownable, Pausable, ERC721 {

    uint256 public mintCount;
    uint256 public burnCount;
    uint256 public maxSupply;
    uint256 public price;

    mapping(uint256 => string) private _tokenURIs;

    /// @dev reverts if any tokens have been minted
    modifier onlyPreMint() {
        require(mintCount == 0, "Must be pre mint");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, uint256 price_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        price = price_;
    }

    /// @dev toggles paused state
    function togglePaused() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @dev sets a new price value
    /// @param newPrice value of new price
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /// @dev mints the next tokenId to msg.sender if price is paid
    function mint() public payable whenNotPaused {
        //validate
        require(msg.value == price, "Must send exact value to mint");

        //send eth to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(msg.sender, mintCount + 1);
    }

    /// @dev burns a token by setting its ownership to the zero address
    /// @param tokenId id of token to burn
    function burn(uint256 tokenId) public whenNotPaused {
        //validate
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");

        _burn(tokenId);
    }

    /// @dev returns token URI
    /// @return uri string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
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
    // receive() external payable {}

    /// @dev fallback function is called when msg.data is not empty
    // fallback() external payable {}
}