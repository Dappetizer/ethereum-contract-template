// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FlatPriceERC721 is Ownable, Pausable, ERC721 {

    uint256 public mintCount;
    uint256 public burnCount;
    uint256 public maxSupply;
    uint256 public basePrice = 1000000000000000000; //1 ETH
    string public baseURI;
    uint256 public freeMints; //token id < freeMints are free to mint

    /// @dev reverts if any tokens have been minted
    modifier onlyPreMint() {
        require(mintCount == 0, "Must be before first mint");
        _;
    }

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

    /// @dev mints the next tokenId to msg.sender if min value is paid
    function mint() public payable whenNotPaused {
        if (mintCount > freeMints) {
            //validate
            require(msg.value == basePrice, "Must send exact value to mint");
        }

        //send eth to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(msg.sender, mintCount);
    }

    /// @dev mints the tokenId and forwards data if min value is paid
    /// @param data extra bytes data to pass along
    function mint(bytes memory data) public payable whenNotPaused {
        if (mintCount > freeMints) {
            //validate
            require(msg.value == basePrice, "Must send exact value to mint");
        }

        //send eth to owner address
        (bool sent, bytes memory data_) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(msg.sender, mintCount, data);
    }

    /// @dev burns a token by setting its ownership to the zero address
    /// @param tokenId id of token to burn
    function burn(uint256 tokenId) public whenNotPaused {
        //validate
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");

        _burn(tokenId);
    }

    /// @dev sets a new basePrice value
    /// @param newBasePrice value of new basePrice
    function setBasePrice(uint256 newBasePrice) public onlyOwner {
        basePrice = newBasePrice;
    }

    /// @dev sets a new free mints count
    function setFreeMints(uint256 newFreeMints) public onlyOwner onlyPreMint {
        freeMints = newFreeMints;
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
    // receive() external payable {}

    /// @dev fallback function is called when msg.data is not empty
    // fallback() external payable {}
}