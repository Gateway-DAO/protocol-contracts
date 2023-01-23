// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GatewayID
 * @dev NatSpec documentation for the GatewayID smart contract.
 */
contract GatewayID is Ownable {
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
        address wallet;
        bytes32 pkh;
        bytes32 proof;
        Type wallet_type;
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
            msg.sender == wallets[master_wallet_idx].wallet &&
                wallets[master_wallet_idx].is_master == true,
            "GatewayID: Not master wallet"
        );
        _;
    }

    /**
     * @dev Modifier to ensure that only the signer wallet can execute the function
     */
    modifier isSigner() {
        require(
            msg.sender == wallets[signer_wallet_idx].wallet ||
                msg.sender == wallets[master_wallet_idx].wallet,
            "GatewayID: Not signer wallet"
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
     */
    modifier isMember(bytes32 _pkh) {
        require(
            msg.sender == wallets[signer_wallet_idx].wallet ||
                msg.sender == wallets[master_wallet_idx].wallet ||
                wallets[abi.encodePacked(bytes32(_pkh), msg.sender)].wallet !=
                address(0x0),
            "GatewayID: Not a member"
        );
        _;
    }

    /**
     * @dev Constructor to initialize the master wallet index
     */
    constructor(address _master, address _signer) {
        address master = _master == address(0x0) ? msg.sender : _master;
        master_wallet_idx = abi.encodePacked(bytes32(0x0), master);
        wallet_indices.push(master_wallet_idx);
        wallets[master_wallet_idx] = Wallet(
            wallet_indices.length,
            master,
            0x0,
            0x0,
            Type.EVM,
            true,
            false
        );

        if (_signer != address(0x0)) {
            signer_wallet_idx = abi.encodePacked(bytes32(0x0), _signer);
            wallet_indices.push(signer_wallet_idx);
            wallets[signer_wallet_idx] = Wallet(
                wallet_indices.length,
                _signer,
                0x0,
                0x0,
                Type.EVM,
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
        return wallets[master_wallet_idx].wallet;
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
     */
    function addEVMWallet(address _wallet)
        public
        onlyOwner
        returns (bool _success)
    {
        require(
            wallets[abi.encodePacked(address(0x0), msg.sender)].wallet ==
                address(0x0),
            "GatewayID: Wallet already exists"
        );

        wallet_indices.push(abi.encodePacked(address(0x0), msg.sender));
        wallets[abi.encodePacked(address(0x0), msg.sender)] = Wallet(
            wallet_indices.length - 1,
            _wallet,
            0x0,
            0x0,
            Type.EVM,
            false,
            false
        );

        return true;
    }

    /**
     * @dev Function to remove an EVM wallet from the mapping
     * @param _member The address of the wallet to be removed
     */
    function removeEVMWallet(address _member) public isMember(bytes32(0x0)) {
        bytes memory id = abi.encodePacked(bytes32(0x0), _member);

        require(
            wallets[id].wallet_type == Type.EVM,
            "GatewayID: Not an EVM wallet"
        );
        require(
            wallets[id].is_master == false,
            "GatewayID: Cannot remove master wallet"
        );

        bytes memory keyToMove = wallet_indices[wallet_indices.length - 1];
        uint256 rowToReplace = wallets[id].idx;
        wallets[keyToMove].idx = rowToReplace;
        wallet_indices[rowToReplace] = keyToMove;

        delete wallets[id];
        wallet_indices.pop();
    }

    /**
     * @dev Function to change the master/owner of the contract
     * @param _member The address of the new master
     */
    function changeMaster(address _member)
        public
        isMaster
        returns (bool _success)
    {
        require(
            wallets[abi.encodePacked(bytes32(0x0), _member)].wallet !=
                address(0x0),
            "GatewayID: Not a member"
        );
        require(
            wallets[abi.encodePacked(bytes32(0x0), _member)].wallet_type ==
                Type.EVM,
            "GatewayID: Not an EVM wallet"
        );

        wallets[abi.encodePacked(bytes32(0x0), _member)].is_master = true;
        wallets[master_wallet_idx].is_master = false;

        master_wallet_idx = abi.encodePacked(bytes32(0x0), _member);
        transferOwnership(_member);

        return true;
    }
}
