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


    /**
     * @dev Credential mapping
     */
    mapping(string => Credential) public credentials;

    /**
     * @dev Modifiers
     */
    modifier onlyIssuer(string memory _id) {
        require(
            msg.sender == credentials[_id].issuer,
            "Credential: Only issuer can call this function"
        );
        _;
    }

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
            _dm_id,
            CredentialStatus.Active,
            block.timestamp,
            _expire_date,
            newCredential.context,
            _metadata_sig,
            new address[](0)
        );
        credentials[_id] = newCredential;
    }

    function isValid(string memory _id) public view returns (bool) {
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

    function reactivateCredential(string memory _id) public onlyIssuer(_id) {
        require(
            credentials[_id].status == CredentialStatus.Suspended,
            "Credential: Credential is not suspended"
        );

        credentials[_id].status = CredentialStatus.Active;
        emit CredentialReactivated(_id);
    }

    function revokeCredential(string memory _id) public onlyIssuer(_id) {
        require(
            credentials[_id].status == CredentialStatus.Active,
            "Credential: Credential is not active");
        
        credentials[_id].status = CredentialStatus.Revoked;
        emit CredentialRevoked(_id);
    }

    function suspendCredential(string memory _id) public onlyIssuer(_id) {
        require(
            credentials[_id].status == CredentialStatus.Active,
            "Credential: Credential is not active"
        );

        credentials[_id].status = CredentialStatus.Suspended;
        emit CredentialSuspended(_id);
    }
}
