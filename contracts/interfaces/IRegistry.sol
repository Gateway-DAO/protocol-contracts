// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRegistry {
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

    /*
     * @dev Events
     */
    event IdentityDeployed(string indexed _username, address indexed _identity);
    event IdentityDeleted(string indexed _username, address indexed _identity);

    function setFactoryAddress(address _factory) external;

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
    ) external returns (bool _success);

    function deployOrgID(
        address _owner,
        address[] memory _signers,
        string memory _username
    ) external returns (bool _success);

    /**
     * getIdentity - returns the address of the GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the GatewayID contract associated with the provided username
     */
    function getIdentity(string memory _username)
        external
        view
        returns (address);

    function getIdentity(address _identity)
        external
        view
        returns (string memory);

    /**
     * getUserIDMasterWallet - returns the address of the master wallet for a GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the master wallet for the GatewayID contract associated with the provided username
     */
    function getUserIDMasterWallet(string memory _username)
        external
        view
        returns (address);

    function getType(string memory _username) external view returns (Type);

    function getType(address _identity) external view returns (Type);

    /**
     * usernameExists - returns a boolean indicating whether a provided username is associated with a GatewayID contract
     * @param _username - bytes32 representing the username to check
     * @return - a boolean indicating whether the provided username is associated with a GatewayID contract
     */
    function usernameExists(string memory _username)
        external
        view
        returns (bool);

    function deleteIdentity(string memory _username) external;

    /* ==== Executors ==== */
    function addExecutor(address _executor) external;

    function removeExecutor(address _executor) external;

    function isAuthorizedExecutor(address _executor)
        external
        view
        returns (bool);
}
