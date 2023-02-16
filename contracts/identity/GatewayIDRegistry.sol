// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UserID.sol";
import "./OrgID.sol";

contract GatewayIDRegistry {
    /*
     * @dev Storage
     */
    enum Type {
        USER,
        ORG
    }

    struct Identity {
        address identity;
        Type IDType;
    }

    mapping(string => Identity) public resolver;
    mapping(address => string) public reverseResolver;
    string[] public usernames;

    address public NFT_FACTORY;

    /*
     * @dev Events
     */
    event IdentityDeployed(string indexed _username, address indexed _identity);
    event IdentityDeleted(string indexed _username, address indexed _identity);

    /**
     * deployUserID - deploys a new GatewayID contract and associates it with a provided username
     * @param _master - address of the master wallet for the new GatewayID contract
     * @param _signer - address of the signer for the new GatewayID contract
     * @param _username - bytes32 representing the username to associate with the new GatewayID contract
     * @return _success - a boolean indicating whether the deployment was successful
     */
    function deployUserID(
        address _master,
        address _signer,
        string memory _username
    ) external returns (bool _success) {
        require(
            resolver[_username].identity == address(0),
            "GatewayIDRegistry: Username already exists"
        );
        UserID newIdentity = new UserID(_master, _signer);
        resolver[_username] = Identity({
            identity: address(newIdentity),
            IDType: Type.USER
        });

        emit IdentityDeployed(_username, address(newIdentity));
        return true;
    }

    function deployOrgID(
        address _owner,
        address[] memory _signers,
        string memory _username
    ) external returns (bool _success) {
        require(
            resolver[_username].identity == address(0),
            "GatewayIDRegistry: Username already exists"
        );
        OrgID newIdentity = new OrgID(_owner, _signers, NFT_FACTORY);
        resolver[_username] = Identity({
            identity: address(newIdentity),
            IDType: Type.ORG
        });

        emit IdentityDeployed(_username, address(newIdentity));
        return true;
    }

    /**
     * getIdentity - returns the address of the GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the GatewayID contract associated with the provided username
     */
    function getIdentity(
        string memory _username
    ) external view returns (address) {
        return resolver[_username].identity;
    }

    function getIdentity(address _identity) external view returns (string memory) {
        return reverseResolver[_identity];
    }

    /**
     * getUserIDMasterWallet - returns the address of the master wallet for a GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the master wallet for the GatewayID contract associated with the provided username
     */
    function getUserIDMasterWallet(
        string memory _username
    ) external view returns (address) {
        return UserID(resolver[_username].identity).getMasterWallet();
    }

    function getType(string memory _username) external view returns (Type) {
        return resolver[_username].IDType;
    }

    function getType(address _identity) external view returns (Type) {
        return resolver[reverseResolver[_identity]].IDType;
    }

    /**
     * usernameExists - returns a boolean indicating whether a provided username is associated with a GatewayID contract
     * @param _username - bytes32 representing the username to check
     * @return - a boolean indicating whether the provided username is associated with a GatewayID contract
     */
    function usernameExists(
        string memory _username
    ) external view returns (bool) {
        return resolver[_username].identity != address(0);
    }

    function deleteIdentity(string memory _username) external {
        require(
            resolver[_username].identity != address(0),
            "GatewayIDRegistry: Username does not exist"
        );
        emit IdentityDeleted(_username, resolver[_username].identity);
        
        delete resolver[_username].identity;
        delete resolver[_username].IDType;
        delete resolver[_username];
    }
}
