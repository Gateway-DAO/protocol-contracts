// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CredentialNFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping (string => address) private credentialToMinter;
    mapping (string => bytes) private credentialToMetadataSig;
    mapping (uint256 => string) private _tokenIdToCredentialId;

    event CredentialMinted(string indexed credentialId, address indexed minter, uint256 indexed tokenId);
    event MinterRemoved(string indexed credentialId, address indexed minter);
    event MinterRegistered(string indexed credentialId, address indexed minter);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setMinter(string memory _credentialId, address _minter) internal onlyOwner {
        credentialToMinter[_credentialId] = _minter;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function removeMinter(string memory _credentialId, address _minter) external onlyOwner {
        require(credentialToMinter[_credentialId] == _minter, "CredentialNFT: Minter is not registered for this credential");
        delete credentialToMinter[_credentialId];
        emit MinterRemoved(_credentialId, _minter);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) override(ERC721, ERC721Enumerable) internal {
        require(from == address(0) || to == address(0), "CredentialNFT: You cannot transfer the NFT to other accounts.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function registerCredential(string memory _credentialId, address _recipient) external onlyOwner {
        require(_recipient != address(0), "CredentialNFT: Recipient cannot be the zero address");

        // Register the credential and authorize the caller to mint NFTs for it
        setMinter(_credentialId, _recipient);
        emit MinterRegistered(_credentialId, _recipient);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
         if (bytes(tokenURI(tokenId)).length != 0) {
            _setTokenURI(tokenId, "");
        }
    }

    function isValid(string memory _tokenURI, bytes memory _metadataSig) public view returns (bool) {
        // Recover the signer from the metadata signature
        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(bytes(_tokenURI)),
            _metadataSig
        );

        // Ensure the signer is the owner of the CredentialNFT contract
        return recovered == owner();
    }

    function mintNFT(string memory _credentialId, string memory _tokenURI, bytes memory _metadataSig) external {
        require(_msgSender() == credentialToMinter[_credentialId], "CredentialNFT: Only the registered minter can mint NFTs for this credential");

        // Ensure the credential is valid
        require(isValid(_tokenURI, _metadataSig), "CredentialNFT: Invalid metadata");

        // Mint the NFT and transfer it to the minter
        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit CredentialMinted(_credentialId, _msgSender(), tokenId);
    }   
}