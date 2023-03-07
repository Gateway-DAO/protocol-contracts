// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UserID
 * @dev NatSpec documentation for the UserID smart contract.
 */
contract UserID is Ownable {
    /**
     * @dev Enum to represent the type of wallet
     */
    enum Type {
        EVM,
        Email,
        Solana
    }

    /**
     * @dev Structure defining a wallet
     */
    struct Wallet {
        uint256 idx;
        address evm_wallet;
        bytes32 evm_pkh;
        bytes32 evm_proof;
        address sol_wallet;
        bytes32 sol_pkh;
        bytes32 sol_proof;
        bool is_master;
        bool is_signer;
    }

    /**
     * @dev The index of the master wallet
     */
    bytes master_wallet_idx;

    /**
     * @dev The index of the signer wallet
     */
    bytes signer_wallet_idx;

    /**
     * @dev Mapping of wallet index and wallet details
     */
    mapping(bytes => Wallet) wallets;
    bytes[] public wallet_indices;

    /**
     * @dev Modifier to ensure that only the master wallet can execute the function
     */
    modifier isMaster() {
        require(
            msg.sender == wallets[master_wallet_idx].evm_wallet ||
                msg.sender == wallets[master_wallet_idx].sol_wallet,
            "UserID: Not master wallet"
        );
        _;
    }

    /**
     * @dev Modifier to ensure that only the signer wallet can execute the function
     */
    modifier isSigner() {
        require(
            msg.sender == wallets[signer_wallet_idx].evm_wallet ||
                msg.sender == wallets[signer_wallet_idx].sol_wallet ||
                msg.sender == wallets[master_wallet_idx].evm_wallet ||
                msg.sender == wallets[master_wallet_idx].sol_wallet,
            "UserID: Not signer wallet"
        );
        _;
    }

    /**
     * @dev Events
     */

    event WalletAdded(
        bytes32 indexed _pkh,
        address indexed _wallet,
        Type _wallet_type
    );

    event WalletRemoved(
        bytes32 indexed _pkh,
        address indexed _wallet,
        Type _wallet_type
    );

    event WalletUpdated(
        bytes32 indexed _pkh,
        address indexed _wallet,
        Type _wallet_type
    );

    /**
     * @dev Modifier to ensure that only a member wallet can execute the function
     * @param _pkh The public key hash of the wallet
     */
    modifier isMember(bytes32 _pkh) {
        bytes memory id = getWalletKey(msg.sender, Type.EVM, _pkh);

        require(
            msg.sender == wallets[master_wallet_idx].evm_wallet ||
                msg.sender == wallets[master_wallet_idx].sol_wallet ||
                msg.sender == wallets[signer_wallet_idx].evm_wallet ||
                msg.sender == wallets[signer_wallet_idx].sol_wallet ||
                wallets[id].evm_wallet != address(0x0) ||
                wallets[id].sol_wallet != address(0x0),
            "UserID: Not a member"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the master wallet index
     */
    constructor(address _master, address _signer) {
        address master = _master == address(0x0) ? msg.sender : _master;
        master_wallet_idx = getWalletKey(master, Type.EVM, bytes32(0));
        wallet_indices.push(master_wallet_idx);
        wallets[master_wallet_idx] = Wallet(
            wallet_indices.length,
            master,
            bytes32(0),
            bytes32(0),
            address(0),
            bytes32(0),
            bytes32(0),
            true,
            false
        );

        if (_signer != address(0x0)) {
            signer_wallet_idx = getWalletKey(_signer, Type.EVM, bytes32(0));
            wallet_indices.push(signer_wallet_idx);
            wallets[signer_wallet_idx] = Wallet(
                wallet_indices.length,
                _signer,
                bytes32(0),
                bytes32(0),
                address(0),
                bytes32(0),
                bytes32(0),
                false,
                true
            );
        }

        transferOwnership(master);
    }

    /**
     * @dev Function to get the master wallet
     */
    function getMasterWallet() public view returns (address) {
        bytes memory key = master_wallet_idx;
        Type walletType = wallets[key].evm_wallet != address(0)
            ? Type.EVM
            : wallets[key].sol_wallet != address(0)
            ? Type.Solana
            : Type.EVM; // default to EVM wallet type

        if (walletType == Type.EVM) {
            return wallets[key].evm_wallet;
        } else if (walletType == Type.Solana) {
            bytes memory publicKey = abi.encodePacked(wallets[key].sol_pkh);
            address ethAddress = address(
                uint160(uint256(keccak256(publicKey)))
            );
            return ethAddress;
        } else {
            revert("UserID: Invalid wallet type");
        }
    }

    /**
     * @dev Function to get the master wallet
     */
    function noOfWallets() public view returns (uint256) {
        return wallet_indices.length;
    }

    /**
     * @dev Function to add a wallet to the mapping
     * @param _wallet The address of the wallet
     * @param _wallet_type The type of wallet (EVM or Solana)
     */
    function addWallet(
        address _wallet,
        Type _wallet_type
    ) public onlyOwner returns (bool _success) {
        bytes32 pkh = getPkh(_wallet, _wallet_type);
        bytes32 proof;

        if (_wallet_type == Type.EVM) {
            proof = keccak256(abi.encodePacked(pkh, msg.sender));
        } else if (_wallet_type == Type.Solana) {
            proof = keccak256(abi.encodePacked(pkh, msg.sender));
        } else {
            revert("UserID: Invalid wallet type");
        }

        bytes memory id = getWalletKey(msg.sender, _wallet_type, pkh);

        require(
            wallets[id].evm_wallet == address(0x0) &&
                wallets[id].sol_wallet == address(0x0),
            "UserID: Wallet already exists"
        );

        wallet_indices.push(id);
        wallets[id] = Wallet(
            wallet_indices.length - 1,
            _wallet_type == Type.EVM ? _wallet : address(0x0),
            _wallet_type == Type.EVM ? pkh : bytes32(0x0),
            _wallet_type == Type.EVM ? proof : bytes32(0x0),
            _wallet_type == Type.Solana ? _wallet : address(0x0),
            _wallet_type == Type.Solana ? pkh : bytes32(0x0),
            _wallet_type == Type.Solana ? proof : bytes32(0x0),
            false,
            false
        );

        emit WalletAdded(pkh, _wallet, _wallet_type);

        return true;
    }

    /**
     * @dev Function to remove a wallet from the mapping
     * @param _wallet The address of the wallet to be removed
     * @param _wallet_type The type of wallet (EVM or Solana)
     */
    function removeWallet(
        address _wallet,
        Type _wallet_type
    ) public isMember(getPkh(_wallet, _wallet_type)) {
        bytes32 pkh = getPkh(_wallet, _wallet_type);
        bytes memory id = getWalletKey(msg.sender, _wallet_type, pkh);

        require(
            wallets[id].is_master == false,
            "UserID: Cannot remove master wallet"
        );

        uint256 rowToReplace = wallets[id].idx;
        bytes memory keyToMove = wallet_indices[wallet_indices.length - 1];
        wallets[keyToMove].idx = rowToReplace;
        wallet_indices[rowToReplace] = keyToMove;
        delete wallets[id];
        wallet_indices.pop();

        emit WalletRemoved(pkh, _wallet, _wallet_type);
    }

    /**
     * @dev Function to change the master/owner of the contract
     * @param _member The address of the new master
     */
    function changeMaster(
        address _member
    ) public isMaster returns (bool _success) {
        bytes memory memberWalletKey = getWalletKey(_member, Type.EVM, bytes32(0x0));
        
        require(
            wallets[memberWalletKey].evm_wallet != address(0x0),
            "UserID: Not a member"
        );

        wallets[memberWalletKey].is_master = true;
        wallets[master_wallet_idx].is_master = false;

        master_wallet_idx = memberWalletKey;
        transferOwnership(_member);

        return true;
    }

    /**
     * ==== Utils ====
     */

    /**
     * @dev Function to get the public key hash of a wallet
     * @param _wallet The address of the wallet
     * @param _wallet_type The type of wallet (EVM or Solana)
     */
    function getPkh(
        address _wallet,
        Type _wallet_type
    ) internal pure returns (bytes32) {
        if (_wallet_type == Type.EVM) {
            return keccak256(abi.encodePacked(_wallet));
        } else if (_wallet_type == Type.Solana) {
            return bytes32(uint256(uint160(_wallet)));
        } else {
            revert("UserID: Invalid wallet type");
        }
    }

    function getWalletKey(
        address wallet,
        Type walletType,
        bytes32 pkh
    ) internal pure returns (bytes memory) {
        require(wallet != address(0), "UserID: Invalid wallet address");

        bytes memory key = abi.encodePacked(pkh);

        if (walletType == Type.EVM) {
            key = abi.encodePacked(key, abi.encodePacked(address(wallet)));
        } else if (walletType == Type.Solana) {
            key = abi.encodePacked(key, abi.encodePacked(bytes20(wallet)));
        } else {
            revert("UserID: Invalid wallet type");
        }

        return key;
    }
}
