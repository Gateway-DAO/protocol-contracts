// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CredentialNFT.sol";

contract CredentialNFTFactory is Ownable {
    mapping (bytes32 => address) public orgToCredentialNFT;

    event CredentialNFTDeployed(bytes32 indexed orgId, address indexed credentialNFT);

    function deployCredentialNFT(bytes32 _orgId, string memory _name, string memory _symbol) public onlyOwner {
        require(orgToCredentialNFT[_orgId] == address(0), "CredentialNFTFactory: Organization has already deployed a CredentialNFT contract");
        CredentialNFT credentialNFT = new CredentialNFT(_name, _symbol);
        credentialNFT.transferOwnership(msg.sender);
        orgToCredentialNFT[_orgId] = address(credentialNFT);
        emit CredentialNFTDeployed(_orgId, address(credentialNFT));
    }

    function getCredentialNFT(bytes32 _orgId) public view returns (address) {
        return orgToCredentialNFT[_orgId];
    }
}