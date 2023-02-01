// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UserID.sol";

contract GatewayIDRegistry {
    mapping(bytes32 => address) public identities;
    bytes32[] public usernames;

    /*
     * @dev Events
     */

    event IdentityDeployed(
        bytes32 indexed _username,
        address indexed _identity
    );

    /**
     * deployIdentity - deploys a new GatewayID contract and associates it with a provided username
     * @param _master - address of the master wallet for the new GatewayID contract
     * @param _signer - address of the signer for the new GatewayID contract
     * @param _username - bytes32 representing the username to associate with the new GatewayID contract
     * @return _success - a boolean indicating whether the deployment was successful
     */
    function deployIdentity(
        address _master,
        address _signer,
        bytes32 _username
    ) external returns (bool _success) {
        require(
            identities[_username] == address(0),
            "GatewayIDRegistry: Username already exists"
        );
        UserID newIdentity = new UserID(_master, _signer);
        identities[_username] = address(newIdentity);
        return true;
    }

    /**
     * getIdentity - returns the address of the GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the GatewayID contract associated with the provided username
     */
    function getIdentity(bytes32 _username) external view returns (address) {
        return identities[_username];
    }

    /**
     * getMasterWallet - returns the address of the master wallet for a GatewayID contract associated with a provided username
     * @param _username - bytes32 representing the username associated with the desired GatewayID contract
     * @return - the address of the master wallet for the GatewayID contract associated with the provided username
     */
    function getMasterWallet(bytes32 _username)
        external
        view
        returns (address)
    {
        return UserID(identities[_username]).getMasterWallet();
    }

    /**
     * usernameExists - returns a boolean indicating whether a provided username is associated with a GatewayID contract
     * @param _username - bytes32 representing the username to check
     * @return - a boolean indicating whether the provided username is associated with a GatewayID contract
     */
    function usernameExists(bytes32 _username) external view returns (bool) {
        return identities[_username] != address(0);
    }
}
