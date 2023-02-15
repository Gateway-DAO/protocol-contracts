// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CredentialNFT is ERC721, ERC721URIStorage, Ownable {
    mapping (string => address) private credentialToMinter;
    mapping (string => bytes) private credentialToMetadataSig;

    event CredentialMinted(string indexed credentialId, address indexed minter, uint256 indexed tokenId);
    event MinterRemoved(string indexed credentialId, address indexed minter);
    event MinterRegistered(string indexed credentialId, address indexed minter);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function setMinter(string memory _credentialId, address _minter) internal onlyOwner {
        credentialToMinter[_credentialId] = _minter;
    }

    function removeMinter(string memory _credentialId, address _minter) external onlyOwner {
        require(credentialToMinter[_credentialId] == _minter, "CredentialNFT: Minter is not registered for this credential");
        delete credentialToMinter[_credentialId];
        emit MinterRemoved(_credentialId, _minter);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) override internal {
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
        require(credentialToMinter[_credentialId] == msg.sender, "CredentialNFT: Only the registered minter can mint NFTs for this credential");

        // Ensure the credential is valid
        require(isValid(_tokenURI, _metadataSig), "CredentialNFT: Invalid metadata");

        // Mint the NFT and transfer it to the minter
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_credentialId, msg.sender, block.timestamp)));

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit CredentialMinted(_credentialId, msg.sender, tokenId);
    }
    
}