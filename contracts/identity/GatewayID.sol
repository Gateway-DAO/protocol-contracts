pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GatewayID is Ownable {
    enum Type {EVM, Email, Solana}
    enum Authority {Normal, Signer, Master}

    struct Wallet {
        address wallet;
        bytes32 pkh;
        bytes32 proof;
        Type wallet_type;
        Authority authority;
    }

    Wallet master_wallet;
    Wallet signer_wallet;

    mapping(bytes => Wallet) wallets;

    modifier isMaster {
        require(msg.sender == master_wallet.wallet, "GatewayID: Not master wallet");
        _;
    }

    modifier isSigner {
        require(msg.sender == signer_wallet.wallet, "GatewayID: Not signer wallet");
        _;
    }

    modifier isMember(bytes32 _pkh) {
        require(msg.sender == signer_wallet.wallet || msg.sender == master_wallet.wallet || wallets[abi.encodePacked(_pkh, msg.sender)].wallet != address(0x0), "GatewayID: Not a member");
        _;
    }

    constructor() {
        master_wallet = Wallet(msg.sender, 0x0, 0x0, Type.EVM, Authority.Master);
        signer_wallet = Wallet(msg.sender, 0x0, 0x0, Type.EVM, Authority.Signer);
    }

    function addWallet(
        address _wallet,
        bytes32 _pkh,
        bytes32 _proof,
        Type _wallet_type,
        Authority _authority
    ) public onlyOwner {
        wallets[abi.encodePacked(_pkh, msg.sender)] = Wallet(_wallet, _pkh, _proof, _wallet_type, _authority);
    }
}