// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract StepSplitERC721 is Ownable, Pausable, ERC721Enumerable {

    uint256 public mintCount;
    uint256 public maxSupply;
    uint256 public stepPrice = 1000000000000000000; //1 ETH
    uint256 public stride = 1; //number of mints per step
    uint256 public steps; //number of steps taken
    uint256 public freeMints; //token id < freeMints are free to mint
    string public baseURI;
    address public splitter; //splitter contract where mint revenue will be sent
    mapping(uint256 => string) public labels; //token id => label
    mapping(uint256 => string) public messages; //token id => message

    /// @dev reverts if any tokens have been minted
    modifier onlyPreMint() {
        require(mintCount == 0, "Must be before first mint");
        _;
    }

    ///@dev reverts if not token owner
    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "only token owner can call");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, address splitter_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        splitter = splitter_;

        //set initial state to paused
        _pause();
    }

    /// @dev toggles paused state
    function togglePaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// @dev gets the price of the next mintable token
    function getPrice() public view returns (uint256) {
        //if next mint is free
        if (mintCount + 1 <= freeMints) {
            return 0;
        }

        //if next mint is new step
        if (((mintCount + 1) - freeMints) % stride == 0) {
            return stepPrice * (steps + 1);
        } else {
            return stepPrice * steps;
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
    function mint(address to) public payable {
        //validate
        require(to != address(0x0), "cannot mint to zero address");
        require(mintCount < maxSupply, "max supply reached");

        //owner can mint while paused
        if (msg.sender != owner()) {
            require(!paused(), "contract is paused");
        }

        //calc price before incrementing mint count
        uint256 price = getPrice();

        mintCount += 1;

        //if no more free mints
        if (mintCount > freeMints) {
            //validate
            require(msg.value == price, "must send exact value to mint");

            if (mintCount % stride == 0) {
                steps += 1;
            }

            //send eth to splitter address
            (bool sent, bytes memory data) = payable(splitter).call{value: msg.value}("");
            require(sent, "Failed to send to splitter address");
        } else {
            //validate
            // require(msg.sender == owner(), "only owner can free mint");
            require(msg.value == 0, "value sent on free mint");
        }

        _safeMint(to, mintCount);
    }

    /// @dev sets a new label for token id
    function setLabel(uint256 tokenId, string memory newLabel) public onlyTokenOwner(tokenId) {
        labels[tokenId] = newLabel;
    }

    /// @dev sets a new message for token id
    function setMessage(uint256 tokenId, string memory newMessage) public onlyTokenOwner(tokenId) {
        messages[tokenId] = newMessage;
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

}