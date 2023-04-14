// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract CredentialNFTV2 is ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping (string => address) private credentialToMinter;
    mapping (string => bytes) private credentialToMetadataSig;
    mapping (uint256 => string) private _tokenIdToCredentialId;
    

    event CredentialMinted(string indexed credentialId, address indexed minter, uint256 indexed tokenId);
    event MinterRemoved(string indexed credentialId, address indexed minter);
    event MinterRegistered(string indexed credentialId, address indexed minter);

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol) initializer public {
        __ERC721_init(_name, _symbol);
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function getMinter(string memory _credentialId) public view returns (address) {
        return credentialToMinter[_credentialId];
    }

    function setMinter(string memory _credentialId, address _minter) internal {
        credentialToMinter[_credentialId] = _minter;
        emit MinterRegistered(_credentialId, _minter);
    }
    
    function removeMinter(string memory _credentialId, address _minter) external {
        require(credentialToMinter[_credentialId] == _minter, "CredentialNFT: Minter is not registered for this credential");
        delete credentialToMinter[_credentialId];
        emit MinterRemoved(_credentialId, _minter);
    }

    function pause() public {
        _pause();
    }

    function unpause() public {
        _unpause();
    }

    function isValid(string memory _tokenURI, bytes memory _metadataSig) public view returns (bool) {
        // Recover the signer from the metadata signature
        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(bytes(_tokenURI)),
            _metadataSig
        );

        // Ensure the signer is the owner of the CredentialNFT contract
        return hasRole(DEFAULT_ADMIN_ROLE, recovered);
    }

    function registerCredential(string memory _credentialId, address _recipient) external {
        require(_recipient != address(0), "CredentialNFT: Recipient cannot be the zero address");

        // Register the credential and authorize the caller to mint NFTs for it
        setMinter(_credentialId, _recipient);
        emit MinterRegistered(_credentialId, _recipient);
    }

    function mintNFT(string memory _credentialId, string memory _tokenURI) external whenNotPaused {
        // require(_msgSender() == credentialToMinter[_credentialId], "CredentialNFT: Only the registered minter can mint NFTs for this credential");

        // Ensure the credential is valid
        // require(isValid(_tokenURI, _metadataSig), "CredentialNFT: Invalid metadata");

        // Mint the NFT and transfer it to the minter
        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        _safeMint(credentialToMinter[_credentialId], tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit CredentialMinted(_credentialId, credentialToMinter[_credentialId], tokenId);
    }   

    /* ===== OVERRIDES ===== */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}