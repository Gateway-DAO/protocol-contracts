// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ICredential.sol";
import "../interfaces/IRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UserID {
    enum Type {
        EVM,
        Solana
    }

    struct Wallet {
        bytes32 public_key;
        Type wallet_type;
    }

    mapping(bytes32 => Wallet) public wallets;
    address public REGISTRY;

    // address public owner;

    event UserInitialized(Wallet[] wallets);
    event WalletAdded(bytes32 public_key, Type wallet_type);
    event WalletRemoved(bytes32 public_key);

    constructor(Wallet[] memory _wallets, address _registry) {
        for (uint256 i = 0; i < _wallets.length; i++) {
            addWallet(_wallets[i].public_key, _wallets[i].wallet_type);
        }

        REGISTRY = _registry;

        emit UserInitialized(_wallets);
    }

    modifier isExecutor() {
        require(
            IRegistry(REGISTRY).isAuthorizedExecutor(msg.sender),
            "UserID: Only executors can perform this action"
        );
        _;
    }

    modifier isMember() {
        require(
            wallets[getId(addressToBytes32(msg.sender), Type.EVM)].public_key ==
                addressToBytes32(msg.sender),
            "UserID: Not a member"
        );
        _;
    }

    modifier isMemberOrExecutor() {
        require(
            (
                addressToBytes32(REGISTRY) != bytes32(0)
                    ? IRegistry(REGISTRY).isAuthorizedExecutor(msg.sender)
                    : true
            ) ||
                wallets[getId(addressToBytes32(msg.sender), Type.EVM)]
                    .public_key ==
                addressToBytes32(msg.sender),
            "UserID: Not a member or executor"
        );
        _;
    }

    function addWallet(bytes32 _public_key, Type _wallet_type)
        public
        isMemberOrExecutor
    {
        require(_public_key != bytes32(0), "UserID: Public key cannot be 0x0");
        require(
            _wallet_type == Type.EVM || _wallet_type == Type.Solana,
            "UserID: Invalid wallet type"
        );
        require(
            wallets[getId(_public_key, _wallet_type)].public_key == bytes32(0),
            "UserID: Wallet already exists"
        );

        wallets[getId(_public_key, _wallet_type)] = Wallet(
            _public_key,
            _wallet_type
        );

        emit WalletAdded(_public_key, _wallet_type);
    }

    function removeWallet(bytes32 _public_key, Type _wallet_type)
        public
        isMemberOrExecutor
    {
        require(
            wallets[getId(_public_key, _wallet_type)].public_key != bytes32(0),
            "UserID: Wallet does not exist"
        );

        delete wallets[getId(_public_key, _wallet_type)];

        emit WalletRemoved(_public_key);
    }

    function getWallet(bytes32 _public_key, Type _wallet_type)
        public
        view
        returns (Wallet memory)
    {
        return wallets[getId(_public_key, _wallet_type)];
    }

    function getWallet(bytes32 _id) public view returns (Wallet memory) {
        return wallets[_id];
    }

    // Executors will execute this
    function executeTransaction(
        bytes32 _publicKey,
        Type _walletType,
        bytes calldata _data,
        bytes calldata _signature
    ) public isExecutor {
        bytes32 id = getId(_publicKey, _walletType);

        require(
            wallets[id].public_key != bytes32(0),
            "UserID: Wallet does not exist"
        );

        if (wallets[id].wallet_type == Type.Solana) {
            address signer = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(_data),
                _signature
            );
            require(
                IRegistry(REGISTRY).isAuthorizedExecutor(signer),
                "UserID: Invalid signature"
            );
        }

        (bool success, ) = address(this).call(_data);
        require(success, "UserID: Transaction failed");
    }

    /* ==== Credentials ==== */

    function issueCredential(ICredential.Credential memory _credential)
        public
        isMemberOrExecutor
    {
        if (_credential.issuer != address(this)) {
            _credential.issuer = address(this);
        }

        ICredential(REGISTRY).issueCredential(_credential);
    }

    function revokeCredential(string memory _id) public isMemberOrExecutor {
        ICredential(REGISTRY).revokeCredential(_id);
    }

    function suspendCredential(string memory _id) public isMemberOrExecutor {
        ICredential(REGISTRY).suspendCredential(_id);
    }

    /* ==== Utils ==== */

    function getId(bytes32 _public_key, Type _wallet_type)
        public
        pure
        returns (bytes32)
    {
        bytes32 padding = _wallet_type == Type.EVM
            ? bytes32("eth:")
            : bytes32("sol:");
        return keccak256(abi.encodePacked(padding, _public_key));
    }

    function addressToBytes32(address _address) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}
