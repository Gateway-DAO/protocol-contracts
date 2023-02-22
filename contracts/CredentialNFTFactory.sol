// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CredentialNFT.sol";
import "./identity/GatewayIDRegistry.sol";

contract CredentialNFTFactory is Ownable {
    mapping (address => address) public orgToCredentialNFT;

    address public gatewayIDRegistry;

    constructor(address _gatewayIDRegistry) {
        gatewayIDRegistry = _gatewayIDRegistry;
    }

    modifier onlyOrg {
        require(GatewayIDRegistry(gatewayIDRegistry).getType(msg.sender) == GatewayIDRegistry.Type.ORG, "CredentialNFTFactory: Only organizations can call this function");
        _;
    }

    event CredentialNFTDeployed(address indexed org, address indexed credentialNFT);

    function deployCredentialNFT(string memory _name, string memory _symbol) external returns (address) {
        require(orgToCredentialNFT[msg.sender] == address(0), "CredentialNFTFactory: Organization has already deployed a CredentialNFT contract");
        
        CredentialNFT credentialNFT = new CredentialNFT(_name, _symbol);
        orgToCredentialNFT[msg.sender] = address(credentialNFT);
        emit CredentialNFTDeployed(msg.sender, address(credentialNFT));

        return address(credentialNFT);
    }

    function getCredentialNFT(address _org) public view returns (address) {
        return orgToCredentialNFT[_org];
    }
}