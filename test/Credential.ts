import { Contract } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("CredentialContract", () => {
  let contract: Contract;
  let signers: SignerWithAddress[];
  let issuer: string, target: string;

  beforeEach(async () => {
    const CredentialContract = await ethers.getContractFactory(
      "CredentialContract"
    );
    contract = await CredentialContract.deploy();

    signers = await ethers.getSigners();
    issuer = await signers[0].getAddress();
    target = await signers[1].getAddress();
  });

  it("Should be able to issue a credential", async () => {
    const id = ethers.utils.formatBytes32String("1234567890");
    const url = "https://example.com";
    const dm_id = ethers.utils.formatBytes32String("0987654321");
    const name = "Example Credential";
    const description = "This is an example credential";
    const revoked_conditions =
      "This credential will be revoked if the user is above 21 years old.";
    const suspended_conditions =
      "This credential will be suspended if the user is above 21 years old.";
    const metadata_sig = await signers[0].signMessage(url);

    await contract.issueCredential(
      id,
      issuer,
      target,
      url,
      dm_id,
      name,
      description,
      revoked_conditions,
      suspended_conditions,
      metadata_sig
    );

    const credential = await contract.credentials(id);
    expect(credential.id).to.equal(id);
    expect(credential.issuer).to.equal(issuer);
    expect(credential.target).to.equal(target);
    expect(credential.metadata_url).to.equal(url);
    expect(credential.dm_id).to.equal(dm_id);
    expect(credential.status).to.equal(0);
    expect(credential.context.name).to.equal(name);
    expect(credential.context.description).to.equal(description);
    expect(credential.context.revoked_conditions).to.equal(revoked_conditions);
    expect(credential.context.suspended_conditions).to.equal(
      suspended_conditions
    );
    expect(credential.metadata_sig).to.equal(metadata_sig);
  });

  it("Should only be able to be issued by the contract owner", async () => {
    const signer = await signers[2];

    const id = ethers.utils.formatBytes32String("1234567890");
    const url = "https://example.com";
    const dm_id = ethers.utils.formatBytes32String("0987654321");
    const name = "Example Credential";
    const description = "This is an example credential";
    const revoked_conditions =
      "This credential will be revoked if the user is above 21 years old.";
    const suspended_conditions =
      "This credential will be suspended if the user is above 21 years old.";
    const metadata_sig = await signers[0].signMessage(url);

    await expect(
      contract
        .connect(signer)
        .issueCredential(
          id,
          issuer,
          target,
          url,
          dm_id,
          name,
          description,
          revoked_conditions,
          suspended_conditions,
          metadata_sig
        )
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should be able to check if a credential is valid", async () => {
    const id = ethers.utils.formatBytes32String("1234567890");
    const url = "https://example.com";
    const dm_id = ethers.utils.formatBytes32String("0987654321");
    const name = "Example Credential";
    const description = "This is an example credential";
    const revoked_conditions =
      "This credential will be revoked if the user is above 21 years old.";
    const suspended_conditions =
      "This credential will be suspended if the user is above 21 years old.";
    const metadata_sig = await signers[0].signMessage(url);

    await contract.issueCredential(
      id,
      issuer,
      target,
      url,
      dm_id,
      name,
      description,
      revoked_conditions,
      suspended_conditions,
      metadata_sig
    );

    const isValid = await contract.isValid(id);
    expect(isValid).to.be.true;
  });

  it("Should not be able to check if an inactive credential is valid", async () => {
    const id = ethers.utils.formatBytes32String("1234567890");
    const url = "https://example.com";
    const dm_id = ethers.utils.formatBytes32String("0987654321");
    const name = "Example Credential";
    const description = "This is an example credential";
    const revoked_conditions =
      "This credential will be revoked if the user is above 21 years old.";
    const suspended_conditions =
      "This credential will be suspended if the user is above 21 years old.";
    const metadata_sig = await signers[0].signMessage(url);

    await contract.issueCredential(
      id,
      issuer,
      target,
      url,
      dm_id,
      name,
      description,
      revoked_conditions,
      suspended_conditions,
      metadata_sig
    );

    //revoke the credential here
    await contract.revokeCredential(id);

    await expect(contract.isValid(id)).to.be.revertedWith(
      "Credential: Credential is not active"
    );
  });
});
