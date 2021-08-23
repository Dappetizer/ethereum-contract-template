// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title A custom ERC721 contract
/// @author Craig Branscom
/// @notice Contract is Ownable and implements the ERC721 spec with Metadata extension.
contract CustomERC721 is Ownable, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _tokenName;
    string private _tokenSymbol;

    uint256 public circulatingSupply; //count of existing tokens (reduced on burn)
    uint256 public totalSupply; //count of all tokens that have existed (including burned)
    uint256 public maxSupply; //supply cap of token

    string public baseURI; //base URI + tokenId returns metadata or metadata link (URL, IPFS, etc.)

    mapping(address => uint256) private _balances; //tracks total token count owned per address
    mapping(uint256 => address) private _owners; //tracks ownership of each token
    mapping(uint256 => address) private _approvals; //approved addresses can transfer token on behalf of token owner
    mapping(address => mapping(address => bool)) private _operators; //approved operators can transfer any token owned by owner (_operators[owner][operator])

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
        _tokenName = name_;
        _tokenSymbol = symbol_;
        maxSupply = maxSupply_;
    }

    //===== Custom Modifiers =====

    /// @dev reverts if token id does not exist
    modifier ifExists(uint256 tokenId) {
        require(_owners[tokenId] != address(0x0), "token id does not exist");
        _;
    }

    /// @dev reverts if token id is not owned by msg.sender
    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == _owners[tokenId], "token id not owned");
        _;
    }

    /// @dev reverts if msg.sender is not owner, approved, or operator
    modifier onlyAuthorized(uint256 tokenId) {
        bool isOwner = _owners[tokenId] == msg.sender;
        bool isApproved = _approvals[tokenId] == msg.sender;
        bool isOperator = _operators[_owners[tokenId]][msg.sender] == true;
        require(isOwner || isApproved || isOperator, "caller neither owner, approved, nor operator");
        _;
    }

    /// @dev reverts if contract can no longer mint
    modifier canMint() {
        require(totalSupply < maxSupply, "cannot mint above max supply");
        _;
    }

    //===== Custom Functions =====

    /// @dev mint new token id to address
    /// @param to address receiving new token
    function mint(address to) public onlyOwner canMint {
        //validate
        require(to != address(0x0), "cannot mint to zero address");

        //calculate new token id
        //TODO: should start at id 0 or 1?
        uint256 newTokenId = totalSupply + 1;

        //update ownership
        _owners[newTokenId] = to;

        //update balance
        _balances[to] += 1;

        //update supply counts
        circulatingSupply += 1;
        totalSupply += 1;

        //minting transfers from the zero address to the recipient
        emit Transfer(address(0x0), to, newTokenId);
    }

    /// @dev removes token id from existence
    /// @param tokenId id of token to burn
    function burn(uint256 tokenId) public ifExists(tokenId) onlyTokenOwner(tokenId) {
        //clear approvals
        delete _approvals[tokenId];

        //TODO: does this need to emit approval event?
        // emit Approval(_owners[tokenId], address(0x0), tokenId);

        //TODO: should operator be allowed to burn?

        //update balance
        _balances[_owners[tokenId]] -= 1;

        //update ownership
        delete _owners[tokenId];

        //burning transfers from owner to zero address
        emit Transfer(msg.sender, address(0x0), tokenId);
    }

    /// @dev update base uri of contract
    /// @param newBaseURI new base uri to set for contract
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    //===== ERC721 =====

    /// @dev gets balance of tokens owned by owner address
    /// @param owner address of owner
    /// @return balance of tokens
    function balanceOf(address owner) public view override returns (uint256 balance) {
        return _balances[owner];
    }

    /// @dev gets owner address of token id
    /// @param tokenId id of token
    /// @return owner of token id
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        //validate
        require(_owners[tokenId] != address(0x0), "token not found");

        return _owners[tokenId];
    }

    /// @dev safely transfer token id to recipient address
    /// @param from address that currently owns token id
    /// @param to address to receive token id
    /// @param tokenId id of token to safely transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) public override ifExists(tokenId) onlyAuthorized(tokenId) {
        require(from != address(0x0), "invalid from address");
        require(to != address(0x0), "invalid to address");

        //update balances
        _balances[from] -= 1;
        _balances[to] += 1;

        //update ownership
        _owners[tokenId] = to;

        //clear previous approval
        delete _approvals[tokenId];

        //TODO: check ERC721Receivable
        // if (to.isContract()) {
        //     try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, bytes("")) returns (bytes4 retval) {
        //         return retval == IERC721Receiver.onERC721Received.selector;
        //     } catch (bytes memory reason) {
        //         if (reason.length == 0) {
        //             revert("ERC721: transfer to non ERC721Receiver implementer");
        //         } else {
        //             assembly {
        //                 revert(add(32, reason), mload(reason))
        //             }
        //         }
        //     }
        // } else {
        //     return true;
        // }

        emit Transfer(from, to, tokenId);
    }

    /// @dev transfers token to recipient
    /// @param from address that currently owns token id
    /// @param to address to receive token id
    /// @param tokenId id of token to transfer
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAuthorized(tokenId) {
        //validate
        require(from != address(0x0), "from cannot be zero address");
        require(to != address(0x0), "to cannot be zero address");

        //update balances
        _balances[from] -= 1;
        _balances[to] += 1;

        //update ownership
        _owners[tokenId] = to;

        //clear previous approval
        delete _approvals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    /// @dev approve an address to transfer token id on behalf of owner
    /// @param to address to approve
    /// @param tokenId token id to approve
    function approve(address to, uint256 tokenId) public override ifExists(tokenId) onlyAuthorized(tokenId) {
        //set new approval
        _approvals[tokenId] = to;

        emit Approval(_owners[tokenId], to, tokenId);
    }

    /// @dev get address approved for token id (if any)
    /// @param tokenId token id to check
    /// @return operator approved for token id
    function getApproved(uint256 tokenId) public override view ifExists(tokenId) returns (address operator) {
        return _approvals[tokenId];
    }

    /// @dev sets approval for all tokens owned by caller
    /// @param operator approval to update
    /// @param approved approval status
    function setApprovalForAll(address operator, bool approved) public override {
        //validate
        require(msg.sender != operator, "operator cannot approve all");

        //update operator status for calling address
        _operators[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev gets approval status for operator on owner address
    /// @param owner address owning tokens
    /// @param operator address with approval status
    /// @return approval status
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operators[owner][operator];
    }

    /// @dev safely trasnfer token to recipient with calldata
    /// @param from address that currently owns token id
    /// @param to address to receive token id
    /// @param tokenId id of token to safely transfer
    /// @param data calldata
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        
        // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    //===== ERC721 Metadata Extension =====

    /// @dev gets token name of contract
    /// @return token name
    function name() public override view returns (string memory) {
        return _tokenName;
    }

    /// @dev gets token symbol of contract
    /// @return token symbol
    function symbol() public override view returns (string memory) {
        return _tokenSymbol;    
    }

    /// @dev gets token uri for token id
    /// @param tokenId id of token
    /// @return token uri
    function tokenURI(uint256 tokenId) public view override ifExists(tokenId) returns (string memory) {
        string memory temp = baseURI;
        return bytes(temp).length > 0 ? string(abi.encodePacked(temp, tokenId.toString(), ".json")) : "";
    }

    //===== ERC165 =====

    /// @dev returns true if this contract supports interface id
    /// @param interfaceId id of interface to check
    /// @return interface support status
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

}