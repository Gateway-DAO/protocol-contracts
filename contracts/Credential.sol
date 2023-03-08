// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CredentialContract is Ownable {
    using Strings for string;

    enum CredentialStatus {
        Active,
        Revoked,
        Suspended,
        Invalid
    }

    struct CredentialContext {
        string name;
        string description;
        string revoked_conditions;
        string suspended_conditions;
    }

    struct CredentialTarget {
        address evm_address;
        string solana_address;
    }

    struct CredentialIssuer {
        address evm_address;
        string solana_address;
    }

    /**
     * @dev Credential struct
     */
    struct Credential {
        string id;
        CredentialIssuer issuer;
        CredentialTarget target;
        string metadata_url;
        string dm_id;
        CredentialStatus status;
        uint256 timestamp;
        uint256 expire_date;
        CredentialContext context;
        bytes metadata_sig;
        address[] permissions;
    }

    /**
     * @dev Events
     */

    event CredentialIssued(
        string id,
        CredentialIssuer issuer,
        CredentialTarget target,
        string url,
        string dm_id,
        CredentialStatus status,
        uint256 timestamp,
        uint256 expire_date,
        CredentialContext context
    );

    event CredentialUpdated(string id, string url, bytes metadata_sig);
    event CredentialRevoked(string id);
    event CredentialSuspended(string id);
    event CredentialReactivated(string id);

    /**
     * @dev Credential mapping
     */
    mapping(string => Credential) public credentials;

    /**
     * @dev Modifiers
     */
    modifier credentialExists(string memory _id) {
        require(
            keccak256(bytes(credentials[_id].id)) == keccak256(bytes(_id)),
            "Credential: Credential does not exist"
        );
        _;
    }

    modifier onlyIssuer(string memory _id) {
        require(
            credentials[_id].issuer.evm_address != address(0) && credentials[_id].issuer.evm_address != address(0),
            "Credential: This issuer wallet is not EVM-based"
        );
        require(
            msg.sender == credentials[_id].issuer.evm_address,
            "Credential: Only issuer can call this function"
        );
        _;
    }

    modifier onlyIssuerOrAuthorized(string memory _id) {
        require(
            (
                credentials[_id].issuer.evm_address != address(0)
                    ? msg.sender == credentials[_id].issuer.evm_address
                    : false
            ) || msg.sender == owner(),
            "Credential: Only issuer or authorized can call this function"
        );
        _;
    }

    function issueCredential(
        string memory _id,
        CredentialIssuer memory _issuer,
        CredentialTarget memory _target,
        string memory _url,
        string memory _dm_id,
        uint256 _expire_date,
        CredentialContext memory _context,
        bytes memory _metadata_sig
    ) public onlyOwner {
        require(
            keccak256(bytes(credentials[_id].id)) != keccak256(bytes(_id)),
            "Credential: Credential already exists"
        );

        Credential memory newCredential = Credential(
            _id,
            _issuer,
            _target,
            _url,
            _dm_id,
            CredentialStatus.Active,
            block.timestamp,
            _expire_date,
            _context,
            _metadata_sig,
            new address[](0)
        );

        emit CredentialIssued(
            _id,
            _issuer,
            _target,
            _url,
            _dm_id,
            CredentialStatus.Active,
            newCredential.timestamp,
            _expire_date,
            _context
        );

        credentials[_id] = newCredential;
    }

    function updateCredential(
        string memory _id,
        string memory _url,
        string memory _name,
        string memory _description,
        string memory _revoked_conditions,
        string memory _suspended_conditions,
        bytes memory _metadata_sig
    ) public credentialExists(_id) onlyIssuerOrAuthorized(_id) {
        Credential storage c = credentials[_id];

        if (
            bytes(_url).length > 0 &&
            keccak256(bytes(c.metadata_url)) != keccak256(bytes(_url))
        ) {
            c.metadata_url = _url;
        }

        if (
            bytes(_name).length > 0 &&
            keccak256(bytes(c.context.name)) != keccak256(bytes(_name))
        ) {
            c.context.name = _name;
        }

        if (
            bytes(_description).length > 0 &&
            keccak256(bytes(c.context.description)) !=
            keccak256(bytes(_description))
        ) {
            c.context.description = _description;
        }

        if (
            bytes(_revoked_conditions).length > 0 &&
            keccak256(bytes(c.context.revoked_conditions)) !=
            keccak256(bytes(_revoked_conditions))
        ) {
            c.context.revoked_conditions = _revoked_conditions;
        }

        if (
            bytes(_suspended_conditions).length > 0 &&
            keccak256(bytes(c.context.suspended_conditions)) !=
            keccak256(bytes(_suspended_conditions))
        ) {
            c.context.suspended_conditions = _suspended_conditions;
        }

        if (
            _metadata_sig.length > 0 &&
            keccak256(c.metadata_sig) != keccak256(_metadata_sig)
        ) {
            c.metadata_sig = _metadata_sig;
        }

        emit CredentialUpdated(_id, c.metadata_url, c.metadata_sig);
    }

    function isValid(
        string memory _id
    ) public view credentialExists(_id) returns (bool) {
        require(
            credentials[_id].issuer.evm_address != address(0),
            "Credential: We can only check the metadata validity of a credential issued by a EVM-compatible wallet"
        );

        bool status = credentials[_id].status == CredentialStatus.Active;
        require(status, "Credential: Credential is not active");

        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(
                abi.encodePacked(credentials[_id].metadata_url)
            ),
            credentials[_id].metadata_sig
        );

        return recovered == credentials[_id].issuer.evm_address;
    }

    function reactivateCredential(
        string memory _id
    ) public credentialExists(_id) onlyIssuerOrAuthorized(_id) {
        require(
            credentials[_id].status == CredentialStatus.Suspended,
            "Credential: Credential is not suspended"
        );

        credentials[_id].status = CredentialStatus.Active;
        emit CredentialReactivated(_id);
    }

    function revokeCredential(
        string memory _id
    ) public credentialExists(_id) onlyIssuerOrAuthorized(_id) {
        require(
            credentials[_id].status == CredentialStatus.Active,
            "Credential: Credential is not active"
        );

        credentials[_id].status = CredentialStatus.Revoked;
        emit CredentialRevoked(_id);
    }

    function suspendCredential(
        string memory _id
    ) public credentialExists(_id) onlyIssuerOrAuthorized(_id) {
        require(
            credentials[_id].status == CredentialStatus.Active,
            "Credential: Credential is not active"
        );

        credentials[_id].status = CredentialStatus.Suspended;
        emit CredentialSuspended(_id);
    }
}
