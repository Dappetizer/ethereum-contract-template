// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StepPriceERC721 is Ownable, Pausable, ERC721 {

    uint256 public mintCount;
    uint256 public burnCount;
    uint256 public maxSupply;
    uint256 public basePrice = 1000000000000000000; //1 ETH
    uint256 public stepAmount = 1000000000000000000; //1 ETH
    uint256 public stride = 1; //number of mints per step
    uint256 public steps = 0; //number of steps taken
    // uint256 public freeMints = 0; //mints for token id < freeMints are free
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

    /// @dev gets the current price of the next mintable token
    function getCurrentPrice() public view returns (uint256) {
        //if next mint is new step
        if ((mintCount + 1) % stride == 0) {
            return ((steps + 1) * stepAmount) + basePrice;
        } else {
            return (steps * stepAmount) + basePrice;
        }
        
    }

    /// @dev mints the next tokenId to msg.sender if min value is paid
    function mint() public payable whenNotPaused {
        //validate
        require(msg.value == getCurrentPrice(), "Must send exact value to mint");

        //send eth to owner address
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send to owner address");

        _safeMint(msg.sender, mintCount);
    }

    /// @dev mints the tokenId and forwards data if min value is paid
    /// @param data extra bytes data to pass along
    function mint(bytes memory data) public payable whenNotPaused {
        //validate
        require(msg.value == getCurrentPrice(), "Must send exact value to mint");

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

            if (mintCount % stride == 0) {
                steps += 1;
            }
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