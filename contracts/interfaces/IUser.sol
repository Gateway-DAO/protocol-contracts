// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ICredential.sol";
import "../interfaces/IRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IUser {
    enum Type {
        EVM,
        Solana
    }

    struct Wallet {
        bytes32 public_key;
        Type wallet_type;
    }

    event UserInitialized(Wallet[] wallets);
    event WalletAdded(bytes32 public_key, Type wallet_type);
    event WalletRemoved(bytes32 public_key);

    function addWallet(bytes32 _public_key, Type _wallet_type) external;

    function removeWallet(bytes32 _public_key) external;

    // Executors will execute this
    function executeTransaction(
        bytes32 _publicKey,
        Type _walletType,
        bytes calldata _data,
        bytes calldata _signature
    ) external;

    /* ==== Credentials ==== */

    function issueCredential(ICredential.Credential memory _credential)
        external;

    function revokeCredential(string memory _id) external;

    function suspendCredential(string memory _id) external;

    /* ==== Utils ==== */

    function getId(bytes32 _public_key, Type _wallet_type)
        external
        pure
        returns (bytes32);

    function addressToBytes32(address _address) external pure returns (bytes32);
}
