// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AssembledERC721 is Ownable, Pausable, ERC721Enumerable {

    uint256 mintCount;
    address partsContract; //ERC721 contract (must be burnable)
    uint256 assemblySize; //number of parts required to assemble token

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC721(name_, symbol_) {
        //validate
        // require(maxSupply > 0, "max supply must be greater than 0");

        // maxSupply = maxSupply_;

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
    /// @param tokenIds array of token Ids from 
    function mint(address to, uint256[] memory tokenIds) public payable whenNotPaused {
        //validate
        require(to != address(0x0), "cannot mint to zero address");
        require(tokenIds.length == assemblySize, "incorrect size for assembly");
        // require(mintCount < maxSupply, "max supply reached");
        // require(msg.value == price, "must send exact value to mint");

        // bytes4 ownerOfSig = bytes4(sha3("ownerOf(uint256)"));
        // bytes4 burnSig = bytes4(sha3("burn(uint256)"));

        //TODO: burn x parts nfts
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //check ownership
            // (bool success, bytes memory data) = partsContract.call(ownerOfSig, i);
            // require(success, "not token owner");

            //burn token
            // (bool success, bytes memory data) = partsContract.call(ownerOfSig, i);
            // require(success, "not token owner");
        }

        mintCount += 1;

        //send native to owner address
        // (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        // require(sent, "Failed to send native to address");

        _safeMint(to, mintCount);
    }
}