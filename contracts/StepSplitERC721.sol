// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StepSplitERC721 is Ownable, Pausable, ERC721 {

    uint256 public mintCount;
    uint256 public burnCount;
    uint256 public maxSupply;
    uint256 public stepPrice = 1000000000000000000; //1 ETH
    uint256 public stride = 1; //number of mints per step
    uint256 public steps = 1; //number of steps taken
    uint256 public freeMints; //token id < freeMints are free to mint
    string public baseURI;
    address public splitter; //splitter contract where mint revenue will be sent

    /// @dev reverts if any tokens have been minted
    modifier onlyPreMint() {
        require(mintCount == 0, "Must be before first mint");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, address splitter_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        splitter = splitter_;

        //TODO: initialize paused?
    }

    /// @dev toggles paused state
    function togglePaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// @dev gets the price of the next mintable token
    function getPrice() public view returns (uint256) {
        //if next mint is new step
        if ((mintCount + 1) % stride == 0) {
            return (steps + 1) * stepPrice;
        } else {
            return steps * stepPrice;
        }
        
    }

    /// @dev sets new step price
    function setStepPrice(uint256 newStepPrice) public onlyOwner onlyPreMint {
        stepPrice = newStepPrice;
    }

    /// @dev sets new stride
    function setStride(uint256 newStride) public onlyOwner onlyPreMint {
        //validate
        require(newStride > 0, "stride must be greater than zero");

        stride = newStride;
    }

    /// @dev sets number of initial free mints
    function setFreeMints(uint256 newFreeMints) public onlyOwner onlyPreMint {
        freeMints = newFreeMints;
    } 

    /// @dev mints the next tokenId to msg.sender if min value is paid
    function mint() public payable whenNotPaused {
        if (mintCount > freeMints) {
            //validate
            require(msg.value == getPrice(), "Must send exact value to mint");
        }

        //send eth to owner address
        (bool sent, bytes memory data) = payable(splitter).call{value: msg.value}("");
        require(sent, "Failed to send to splitter address");

        _safeMint(msg.sender, mintCount);
    }

    /// @dev burns a token by setting its ownership to the zero address
    /// @param tokenId id of token to burn
    function burn(uint256 tokenId) public whenNotPaused {
        //validate
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");

        _burn(tokenId);
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
}