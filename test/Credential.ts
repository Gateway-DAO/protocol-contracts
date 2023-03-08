import { Contract } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("CredentialContract", () => {
    let contract: Contract;
    let signers: SignerWithAddress[];
    let issuer: string, target: string;
    let solanaTarget = "BZGPpxbSYH6B4hr7eXDv4s5LULZv24GB57JzqZd5Qq6D";

    const id = "1234567890";
    const url = "https://example.com";
    const dm_id = "0987654321";
    const expire_date = 1709077869; // 	Tue Feb 27 2024 23:51:09 GMT+0000
    const name = "Example Credential";
    const description = "This is an example credential";
    const revoked_conditions =
        "This credential will be revoked if the user is above 21 years old.";
    const suspended_conditions =
        "This credential will be suspended if the user is above 21 years old.";
    let metadata_sig: string;

    beforeEach(async () => {
        const CredentialContract = await ethers.getContractFactory(
            "CredentialContract"
        );
        contract = await CredentialContract.deploy();

        signers = await ethers.getSigners();
        issuer = await signers[0].getAddress();
        target = await signers[1].getAddress();

        metadata_sig = await signers[0].signMessage(url);

        await contract.issueCredential(
            id,
            [issuer, ""],
            [target, ""],
            url,
            dm_id,
            expire_date,
            {
                name,
                description,
                revoked_conditions,
                suspended_conditions,
            },
            metadata_sig
        );
    });

    it("Should be able to issue a credential", async () => {
        const credential = await contract.credentials(id);

        expect(credential.id).to.equal(id);
        expect(credential.issuer.evm_address).to.equal(issuer);
        expect(credential.target.evm_address).to.equal(target);
        expect(credential.metadata_url).to.equal(url);
        expect(credential.dm_id).to.equal(dm_id);
        expect(credential.status).to.equal(0);
        expect(credential.context.name).to.equal(name);
        expect(credential.context.description).to.equal(description);
        expect(credential.context.revoked_conditions).to.equal(
            revoked_conditions
        );
        expect(credential.context.suspended_conditions).to.equal(
            suspended_conditions
        );
        expect(credential.metadata_sig).to.equal(metadata_sig);
    });

    it("Should be able to issue a credential to a Solana wallet", async () => {
        await contract.issueCredential(
            id + 1,
            [issuer, ""],
            [ethers.constants.AddressZero, solanaTarget],
            url,
            dm_id,
            expire_date,
            {
                name,
                description,
                revoked_conditions,
                suspended_conditions,
            },
            metadata_sig
        );

        const credential = await contract.credentials(id + 1);

        expect(credential.id).to.equal(id + 1);
        expect(credential.issuer.evm_address).to.equal(
            issuer
        );
        expect(credential.target.evm_address).to.equal(
            ethers.constants.AddressZero
        );
        expect(credential.target.solana_address).to.equal(
            solanaTarget
        );
        expect(credential.metadata_url).to.equal(url);
        expect(credential.dm_id).to.equal(dm_id);
        expect(credential.status).to.equal(0);
        expect(credential.context.name).to.equal(name);
        expect(credential.context.description).to.equal(description);
        expect(credential.context.revoked_conditions).to.equal(
            revoked_conditions
        );
        expect(credential.context.suspended_conditions).to.equal(
            suspended_conditions
        );
        expect(credential.metadata_sig).to.equal(metadata_sig);
    });

    it("Should only be able to be issued by the contract owner", async () => {
        const signer = await signers[2];

        await expect(
            contract.connect(signer).issueCredential(
                id +  1,
                [issuer, ""],
                [target, ""],
                url,
                dm_id,
                expire_date,
                {
                    name,
                    description,
                    revoked_conditions,
                    suspended_conditions,
                },
                metadata_sig
            )
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should be able to check if a credential is valid", async () => {
        const isValid = await contract.isValid(id);
        expect(isValid).to.be.true;
    });

    it("Should not be able to check if an inactive credential is valid", async () => {
        await contract.revokeCredential(id);

        await expect(contract.isValid(id)).to.be.revertedWith(
            "Credential: Credential is not active"
        );
    });

    it("should update the credential fields", async function () {
        // Call the function with all optional fields provided
        const sig = await signers[0].signMessage("https://example.com/updated");

        const receipt = await contract.updateCredential(
            id,
            "https://example.com/updated",
            name,
            description,
            revoked_conditions,
            suspended_conditions,
            sig
        );

        // Check that the fields were updated correctly
        const updatedCredential = await contract.credentials(id);
        expect(updatedCredential.metadata_url).to.equal(
            "https://example.com/updated"
        );
        expect(updatedCredential.context.name).to.equal(name);
        expect(updatedCredential.context.description).to.equal(description);
        expect(updatedCredential.context.revoked_conditions).to.equal(
            revoked_conditions
        );
        expect(updatedCredential.context.suspended_conditions).to.equal(
            suspended_conditions
        );
        expect(updatedCredential.metadata_sig).to.equal(sig);

        // Check that the event was emitted correctly
        expect(receipt)
            .to.emit(contract, "CredentialUpdated")
            .withArgs(id, url, sig);
    });

    it("should update only the provided fields", async function () {
        // Call the function with only some optional fields provided
        const sig = await signers[0].signMessage("https://example.com/updated");

        const receipt = await contract.updateCredential(
            id,
            "https://example.com/updated",
            "",
            "",
            "",
            "",
            sig
        );

        // Check that only the provided fields were updated
        const updatedCredential = await contract.credentials(id);
        expect(updatedCredential.metadata_url).to.equal(
            "https://example.com/updated"
        );
        expect(updatedCredential.context.name).to.equal(name);
        expect(updatedCredential.context.description).to.equal(description);
        expect(updatedCredential.context.revoked_conditions).to.equal(
            revoked_conditions
        );
        expect(updatedCredential.context.suspended_conditions).to.equal(
            suspended_conditions
        );
        expect(updatedCredential.metadata_sig).to.equal(sig);

        // Check that the event was emitted correctly
        expect(receipt)
            .to.emit(contract, "CredentialUpdated")
            .withArgs(id, "https://example.com/updated", sig);
    });

    it("should revert if the credential does not exist", async function () {
        // Call the function with an invalid credential ID
        await expect(
            contract.updateCredential(
                "invalid_id",
                url,
                name,
                description,
                revoked_conditions,
                suspended_conditions,
                metadata_sig
            )
        ).to.be.revertedWith("Credential: Credential does not exist");
    });
});
