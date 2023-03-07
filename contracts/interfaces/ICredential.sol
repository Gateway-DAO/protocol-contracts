// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICredential {
    enum CredentialStatus {
        Active,
        Revoked,
        Suspended,
        Invalid
    }

    enum LogEffect {
        CreatedCredential,
        ChangedStatus
    }

    struct CredentialContext {
        string name;
        string description;
        string revoked_conditions;
        string suspended_conditions;
    }

    /**
     * @dev Credential struct
     */
    struct Credential {
        string id;
        address issuer;
        address target;
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
        string id,
        address issuer,
        address target,
        string url,
        string dm_id,
        CredentialStatus status,
        uint256 timestamp,
        uint256 expire_date,
        CredentialContext context,
        bytes metadata_sig,
        address[] permissions
    );

    event CredentialRevoked(string id);
    event CredentialSuspended(string id);
    event CredentialReactivated(string id);

    function issueCredential(
        string memory _id,
        address _issuer,
        address _target,
        string memory _url,
        string memory _dm_id,
        uint256 _expire_date,
        string memory _name,
        string memory _description,
        string memory _revoked_conditions,
        string memory _suspended_conditions,
        bytes memory _metadata_sig
    ) external;

    function issueCredential(Credential memory _credential) external;

    function isValid(string memory _id) external view returns (bool);

    function reactivateCredential(string memory _id) external;

    function revokeCredential(string memory _id) external;

    function suspendCredential(string memory _id) external;
}
