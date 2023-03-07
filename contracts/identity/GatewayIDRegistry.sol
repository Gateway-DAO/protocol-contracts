// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UserID.sol";
import "./OrgID.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GatewayIDRegistry is Ownable {
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

    struct ContractAddresses {
        address credential;
        address dataModel;
        address nftFactory;
    }

    mapping(string => Identity) public resolver;
    mapping(address => string) public reverseResolver;
    string[] public usernames;

    mapping(address => bool) public executors;

    /*
     * @dev Events
     */
    event IdentityDeployed(string indexed _username, address indexed _identity);
    event IdentityDeleted(string indexed _username, address indexed _identity);

    constructor() {}

    function deployUserID(
        UserID.Wallet[] memory _wallets,
        string memory _username
    ) external returns (bool _success) {
        require(
            resolver[_username].identity == address(0),
            "GatewayIDRegistry: Username already exists"
        );
        UserID newIdentity = new UserID(_wallets, address(this));
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
        string memory _username,
        ContractAddresses memory _contractAddresses
    ) external returns (bool _success) {
        require(
            resolver[_username].identity == address(0),
            "GatewayIDRegistry: Username already exists"
        );

        require(
            _owner != address(0),
            "GatewayIDRegistry: Invalid owner address"
        );

        OrgID newIdentity = new OrgID(
            _owner,
            _signers,
            _contractAddresses.nftFactory,
            _contractAddresses.credential,
            _contractAddresses.dataModel
        );
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
    function getIdentity(string memory _username)
        external
        view
        returns (address)
    {
        return resolver[_username].identity;
    }

    function getIdentity(address _identity)
        external
        view
        returns (string memory)
    {
        return reverseResolver[_identity];
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
    function usernameExists(string memory _username)
        external
        view
        returns (bool)
    {
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

    /* ==== Executors ==== */
    function addExecutor(address _executor) external onlyOwner {
        executors[_executor] = true;
    }

    function removeExecutor(address _executor) external onlyOwner {
        executors[_executor] = false;
    }

    function isAuthorizedExecutor(address _executor)
        external
        view
        returns (bool)
    {
        return executors[_executor];
    }
}
