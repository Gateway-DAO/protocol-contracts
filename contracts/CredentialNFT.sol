// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CredentialNFT is ERC721, Ownable {
    mapping (string => address) private credentialToMinter;
    mapping (string => bytes) private credentialToMetadataSig;
    mapping (address => bool) private whitelist;

    event CredentialMinted(string indexed credentialId, address indexed minter, uint256 indexed tokenId);
    event MinterRemoved(string indexed credentialId, address indexed minter);
    event CredentialRegistered(string indexed credentialId, address indexed minter);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function setMinter(string memory _credentialId, address _minter) public onlyOwner {
        require(_minter != address(0), "CredentialNFT: Minter cannot be the zero address");
        credentialToMinter[_credentialId] = _minter;
    }

    function removeMinter(string memory _credentialId, address _minter) external onlyOwner {
        require(credentialToMinter[_credentialId] == _minter, "CredentialNFT: Minter is not registered for this credential");
        delete credentialToMinter[_credentialId];
        emit MinterRemoved(_credentialId, _minter);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) override internal {
        require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function registerCredential(string memory _credentialId, string memory _metadataUrl, bytes memory _metadataSig) external {
        // Verify the metadata signature
        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(bytes(_metadataUrl)),
            _metadataSig
        );
        require(recovered == msg.sender, "CredentialNFT: Invalid metadata signature");

        // Register the credential and authorize the caller to mint NFTs for it
        setMinter(_credentialId, msg.sender);
        credentialToMetadataSig[_credentialId] = _metadataSig; // added
        emit CredentialRegistered(_credentialId, msg.sender);
    }

    function addToWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "CredentialNFT: Address cannot be the zero address");
        whitelist[_address] = true;
    }

    function isValid(string memory _credentialId) public view returns (bool) {
        // Get the metadata signature from the CredentialNFT contract
        bytes memory metadataSig = credentialToMetadataSig[_credentialId];

        // Recover the signer from the metadata signature
        string memory metadataUrl = string(abi.encodePacked("metadata url for ", _credentialId));
        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(bytes(metadataUrl)),
            metadataSig
        );

        // Ensure the signer is the owner of the CredentialNFT contract
        return recovered == owner();
    }

    function mintNFT(string memory _credentialId) external {
        require(whitelist[msg.sender], "CredentialNFT: Only whitelisted addresses can mint NFTs");
        require(credentialToMinter[_credentialId] == msg.sender, "CredentialNFT: Only the registered minter can mint NFTs for this credential");

        // Ensure the credential is valid
        require(isValid(_credentialId), "CredentialNFT: Invalid credential");

        // Mint the NFT and transfer it to the minter
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_credentialId, msg.sender, block.timestamp)));
        _safeMint(msg.sender, tokenId);
        emit CredentialMinted(_credentialId, msg.sender, tokenId);
    }
}