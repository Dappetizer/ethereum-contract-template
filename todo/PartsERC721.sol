// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PartsERC721 is Ownable, Pausable, ERC721Enumerable {

    uint256 mintCount;
    uint256 maxSupply;
    uint256 price;

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC721(name_, symbol_) {
        //validate
        require(maxSupply > 0, "max supply must be greater than 0");

        maxSupply = maxSupply_;

        //start contract paused
        _pause();
    }

    /// @dev toggles paused state
    function togglePaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// @dev mints next token id for price
    /// @notice token ids range from 1 - max supply inclusive
    /// @param to address receiving the new token
    function mint(address to) public payable whenNotPaused {
        //validate
        require(to != address(0x0), "cannot mint to zero address");
        require(mintCount < maxSupply, "max supply reached");
        require(msg.value == price, "must send exact value to mint");

        mintCount += 1;

        //send native to owner address
        // (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        // require(sent, "Failed to send native to address");

        _safeMint(to, mintCount);
    }


    /// @dev convenience function for approving set of token ids
    /// @param to address to approve for all token ids
    /// @param tokenIds list of token ids
    function bulkApprove(address to, uint256[] memory tokenIds) public {
        //validate
        //TODO: check for duplicates?

        //loop over each token id and approve
        for (uint256 i = 0; i < tokenIds.length; i++) {
            approve(to, i);
        }
    }
}