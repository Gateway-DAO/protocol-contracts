// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// OpenZeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./GatewayIDRegistry.sol";
import "../CredentialNFTFactory.sol";
import "../Credential.sol";
import "../DataModel.sol";

import "hardhat/console.sol";

/**
 * @title GatewayID
 * @dev NatSpec documentation for the GatewayID smart contract.
 */
contract OrgID is Ownable, Pausable {
    /**
     * @dev Mapping of wallet index and wallet details
     */
    mapping(address => bool) public members;
    uint256 public member_count;

    address public REGISTRY;
    address public NFT_FACTORY;
    address public DATA_MODEL;
    address public CREDENTIAL;
    address public CREDENTIAL_NFT;

    /**
     * @dev Modifier to ensure that only a signer can execute the function
     */
    modifier isMember() {
        require(members[msg.sender], "OrgID: Not signer");
        _;
    }

    modifier isMemberOrAuthorized(address _target) {
        require(
            members[msg.sender] || GatewayIDRegistry(REGISTRY).validators(_target),
            "OrgID: Not signer or authorized"
        );
        _;
    }

    /**
     * @dev Events
     */

    event OrganizationCreated(address indexed _owner, address[] _signers);
    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);
    event ExecutedTransaction(
        address indexed _to,
        uint256 indexed _value,
        bytes _data
    );

    /**
     * @dev Constructor to initialize the master wallet index
     */
    constructor(
        address _owner,
        address[] memory _signers,
        address _registry,
        address _nftFactory,
        address _credential,
        address _dataModel
    ) {
        require(
            _owner != address(0x0) || _owner != address(this),
            "OrgID: Invalid owner address"
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            require(
                _signers[i] != address(0x0) || _signers[i] != address(this),
                "OrgID: Invalid signer address"
            );
            members[_signers[i]] = true;
            member_count++;
        }

        if (!members[_owner]) {
            members[_owner] = true;
            member_count++;
        }

        // Add contracts to variables
        NFT_FACTORY = _nftFactory;
        DATA_MODEL = _dataModel;
        CREDENTIAL = _credential;

        emit OrganizationCreated(_owner, _signers);
        _transferOwnership(_owner);
    }

    /**
     * @dev Function to add a wallet to the mapping
     * @param _wallet The address of the wallet
     */
    function addMember(address _wallet) public onlyOwner {
        require(!members[_wallet], "Wallet already exists");
        members[_wallet] = true;
        member_count++;

        emit MemberAdded(_wallet);
    }

    /**
     * @dev Function to remove an EVM wallet from the mapping
     * @param _wallet The address of the wallet to be removed
     */
    function removeMember(address _wallet) public onlyOwner {
        require(members[_wallet], "Wallet does not exist");
        delete members[_wallet];
        member_count--;

        emit MemberRemoved(_wallet);
    }

    /**
     * @dev Function to change the owner of the organization
     * @param _newOwner The address of the new master
     */
    function transferOwnership(address _newOwner)
        public
        override(Ownable)
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "OrgID: New owner address cannot be 0x0"
        );

        // Add new owner to members list
        if (!members[_newOwner]) {
            members[_newOwner] = true;
            member_count++;
        }

        // Transfer ownership
        transferOwnership(_newOwner);
    }

    function execTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public payable virtual isMember whenNotPaused returns (bool success) {
        require(_to != address(0), "OrgID: Cannot send to address 0x0");

        (success, ) = _to.call{value: _value}(_data);

        if (success) emit ExecutedTransaction(_to, _value, _data);
    }

    /** ===== CREDENTIALS ===== */

    function deployNFTContract(string memory _name, string memory _symbol)
        public
        onlyOwner
        returns (address)
    {
        CREDENTIAL_NFT = CredentialNFTFactory(NFT_FACTORY).deployCredentialNFT(
            _name,
            _symbol
        );

        return CREDENTIAL_NFT;
    }

    function issueCredential(
        string memory _id,
        address _target,
        string memory _url,
        string memory _dm_id,
        uint256 _expire_date,
        string memory _name,
        string memory _description,
        string memory _revoked_conditions,
        string memory _suspended_conditions,
        bytes memory _metadata_sig
    ) public isMember whenNotPaused {
        CredentialContract(CREDENTIAL).issueCredential(
            _id,
            address(this),
            _target,
            _url,
            _dm_id,
            _expire_date,
            _name,
            _description,
            _revoked_conditions,
            _suspended_conditions,
            _metadata_sig
        );
    }

    function revokeCredential(string memory _id) public isMember whenNotPaused {
        CredentialContract(CREDENTIAL).revokeCredential(_id);
    }

    function suspendCredential(string memory _id)
        public
        isMember
        whenNotPaused
    {
        CredentialContract(CREDENTIAL).suspendCredential(_id);
    }

    /** ===== DATA MODELS ===== */

    function createDataModel(
        string memory _id,
        string memory _name,
        string memory _description,
        string memory _url
    ) public isMember whenNotPaused {
        DataModel(DATA_MODEL).createModel(_id, _name, _description, _url);
    }

    function updateDataModel(
        string memory _id,
        string memory _version,
        string memory _url
    ) public isMember whenNotPaused {
        DataModel(DATA_MODEL).createModelVersion(_id, _version, _url);
    }
}
