// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title GatewayID
 * @dev NatSpec documentation for the GatewayID smart contract.
 */
contract OrgID {
    /**
     * @dev Mapping of wallet index and wallet details
     */
    mapping(address => bool) internal members;
    address owner;
    uint256 public member_count;

    /**
     * @dev Modifier to ensure that only the owner can execute the function
     */
    modifier isOwner() {
        require(members[msg.sender] && msg.sender == owner, "OrgID: Not owner");
        _;
    }

    /**
     * @dev Modifier to ensure that only a signer can execute the function
     */
    modifier isMember() {
        require(members[msg.sender], "OrgID: Not signer");
        _;
    }

    /**
     * @dev Events
     */

    event OrganizationCreated(address indexed _owner, address[] _signers);
    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ExecutedTransaction(
        address indexed _to,
        uint256 indexed _value,
        bytes _data
    );

    /**
     * @dev Constructor to initialize the master wallet index
     */
    constructor(address _owner, address[] memory _signers) {
        require(
            _owner != address(0x0) || _owner != address(this),
            "OrgID: Invalid owner address"
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            require(
                _signers[i] != address(0x0) || _signers[i] != address(this),
                "OrgID: Invalid signer address"
            );
            members[_signers[i]] = true;
            member_count++;
        }

        if (!members[_owner]) {
            members[_owner] = true;
            member_count++;
        }

        owner = _owner;

        emit OrganizationCreated(_owner, _signers);
    }

    /**
     * @dev Function to add a wallet to the mapping
     * @param _wallet The address of the wallet
     */
    function addMember(address _wallet) public isOwner {
        require(!members[_wallet], "Wallet already exists");
        members[_wallet] = true;
        member_count++;

        emit MemberAdded(_wallet);
    }

    /**
     * @dev Function to remove an EVM wallet from the mapping
     * @param _wallet The address of the wallet to be removed
     */
    function removeMember(address _wallet) public isOwner {
        require(members[_wallet], "Wallet does not exist");
        delete members[_wallet];
        member_count--;

        emit MemberRemoved(_wallet);
    }

    /**
     * @dev Function to change the owner of the organization
     * @param _newOwner The address of the new master
     */
    function transferOwnership(address _newOwner) public isOwner {
        require(
            _newOwner != address(0),
            "OrgID: New owner address cannot be 0x0"
        );

        // Add new owner to members list
        if (!members[_newOwner]) {
            members[_newOwner] = true;
            member_count++;
        }

        // Transfer ownership
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function execTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public payable virtual isMember returns (bool success) {
        require(_to != address(0), "OrgID: Cannot send to address 0x0");

        (success, ) = _to.call{value: _value}(
            _data
        );

        if (success) emit ExecutedTransaction(_to, _value, _data);
    }
}
