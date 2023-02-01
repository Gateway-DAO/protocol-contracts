pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CredentialContract is Ownable {
    enum CredentialStatus {
        Active,
        Revoked,
        Suspended,
        Invalid
    }

    struct CredentialContext {
        string name;
        string description;
        string revokedConditions;
        string suspendedConditions;
    }

    /**
     * @dev Credential struct
     */
    struct Credential {
        bytes32 id;
        address issuer;
        address target;
        string metadata_url;
        bytes32 dm_id;
        CredentialStatus status;
        uint256 timestamp;
        CredentialContext context;
        bytes metadata_sig;
        address[] permissions;
    }

    /**
     * @dev Credential log
     */
    struct CredentialLog {
        string url;
        uint256 timestamp;
        CredentialStatus status;
    }

    /**
     * @dev Events
     */

    event CredentialIssued(
        bytes32 id,
        address issuer,
        address target,
        string url,
        bytes32 dm_id,
        CredentialStatus status,
        uint256 timestamp,
        CredentialContext context,
        bytes metadata_sig,
        address[] permissions
    );

    event CredentialRevoked(bytes32 id);

    /**
     * @dev Credential mapping
     */
    mapping(bytes32 => Credential) public credentials;
    mapping(bytes32 => mapping(uint256 => CredentialLog)) public credentialLogs;

    function createLog(
        bytes32 _id,
        string memory _url,
        CredentialStatus _status
    ) private {
        uint256 timestamp = block.timestamp;
        credentialLogs[_id][timestamp] = CredentialLog(
            _url,
            timestamp,
            _status
        );
    }

    function issueCredential(
        bytes32 _id,
        address _issuer,
        address _target,
        string memory _url,
        bytes32 _dm_id,
        string memory _name,
        string memory _description,
        string memory _revoked_conditions,
        string memory _suspended_conditions,
        bytes memory _metadata_sig
    ) public onlyOwner {
        Credential memory newCredential = Credential(
            _id,
            _issuer,
            _target,
            _url,
            _dm_id,
            CredentialStatus.Active,
            block.timestamp,
            CredentialContext(
                _name,
                _description,
                _revoked_conditions,
                _suspended_conditions
            ),
            _metadata_sig,
            new address[](0)
        );

        emit CredentialIssued(
            _id,
            _issuer,
            _target,
            _url,
            keccak256(abi.encodePacked(_dm_id)),
            CredentialStatus.Active,
            block.timestamp,
            CredentialContext(
                _name,
                _description,
                _revoked_conditions,
                _suspended_conditions
            ),
            _metadata_sig,
            new address[](0)
        );
        credentials[_id] = newCredential;
        createLog(_id, newCredential.metadata_url, CredentialStatus.Active);
    }

    function isValid(bytes32 _id) public view returns (bool) {
        bool status = credentials[_id].status == CredentialStatus.Active
            ? true
            : false;
        require(status, "Credential: Credential is not active");

        (address recovered, ) = ECDSA.tryRecover(
            ECDSA.toEthSignedMessageHash(
                abi.encodePacked(credentials[_id].metadata_url)
            ),
            credentials[_id].metadata_sig
        );
        return recovered == credentials[_id].issuer ? true : false;
    }

    function revokeCredential(bytes32 _id) public {
        require(
            msg.sender == credentials[_id].issuer,
            "Only issuer can revoke credential"
        );
        emit CredentialRevoked(_id);
        credentials[_id].status = CredentialStatus.Revoked;
        createLog(_id, credentials[_id].metadata_url, CredentialStatus.Revoked);
    }
}
