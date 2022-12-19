pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CredentialContract is Ownable {
    enum CredentialStatus {Active, Revoked, Suspended, Invalid}

    struct CredentialContext {
        bytes32 name;
        bytes32 description;
    }

    /**
      * @dev Credential struct
      */
    struct Credential {
        bytes32 id;
        address issuer;
        address target;
        bytes32 metadata_url;
        bytes32 dm_id;
        CredentialStatus status;
        uint256 timestamp;
        CredentialContext context;
        bytes32 metadata_hash;
    }

    /**
      * @dev Credential log
      */
    struct CredentialLog {
        bytes32 url;
        uint256 timestamp;
        CredentialStatus status;
    }

    /**
      * @dev Credential mapping
      */
    mapping(bytes32 => Credential) public credentials;
    mapping(bytes32 => mapping(uint256 => CredentialLog)) public credentialLogs;

    function createLog(bytes32 _id, bytes32 _url, CredentialStatus _status) private {
        uint256 timestamp = block.timestamp;
        credentialLogs[_id][timestamp] = CredentialLog(url, timestamp, status);
    }

    function issueCredential(
        bytes32 _id,
        address _issuer,
        address _target,
        bytes32 _url,
        bytes32 _dm_id,
        bytes32 _name,
        bytes32 _description,
        bytes32 _metadata_hash
    ) public onlyOwner {
        Credential memory newCredential = Credential(
            _id,
            _issuer,
            _target,
            _url,
            _dm_id,
            CredentialStatus.Active,
            block.timestamp,
            CredentialContext(_name, _description),
            _metadata_hash
        );

        credentials[_id] = newCredential;
        createLog(_id, newCredential.metadata_url, CredentialStatus.Active);
    }

    function isValid(bytes32 _id) public view returns (bool) {
        bool status = credentials[_id].status == CredentialStatus.Active ? true : false;
        address recovered = ecrecover(abi.encodePacked(credentials[_id].metadata_hash), v, r, s);

        return recovered == credentials[_id].issuer ? true : false;
    }

    function revokeCredential(bytes32 _id) public {
        require(msg.sender == credentials[_id].issuer, "Only issuer can revoke credential");
        credentials[_id].status = CredentialStatus.Revoked;
        createLog(_id, credentials[_id].metadata_url, CredentialStatus.Revoked);
    }
}