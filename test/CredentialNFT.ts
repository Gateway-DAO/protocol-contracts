import { Contract } from "ethers";
import { assert, expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("CredentialNFTContract", () => {
    let credentialNFT: Contract;
    let owner: SignerWithAddress;
    let minter: SignerWithAddress;
    let recipient: SignerWithAddress;
    let credentialId: string;
    let tokenURI: string;
    let metadataSig: string;

    beforeEach(async function () {
        [owner, minter, recipient] = await ethers.getSigners();

        const CredentialNFT = await ethers.getContractFactory("CredentialNFT");
        credentialNFT = await CredentialNFT.deploy("MyCredentialNFT", "MCNFT");

        await credentialNFT.deployed();

        credentialId = "0x1234";
        tokenURI = "https://example.com/credential/0x1234";
        metadataSig = await owner.signMessage(tokenURI);

        await credentialNFT.registerCredential(credentialId, minter.address);
    });

    it("should pause and unpause the contract", async function () {
        await credentialNFT.pause();
        assert.equal(await credentialNFT.paused(), true);

        await credentialNFT.unpause();
        assert.equal(await credentialNFT.paused(), false);
    });

    it("should remove a minter", async function () {
        await credentialNFT.removeMinter(credentialId, minter.address);

        await expect(
            credentialNFT
                .connect(minter)
                .mintNFT(credentialId, tokenURI, metadataSig)
        ).to.be.revertedWith(
            "CredentialNFT: Only the registered minter can mint NFTs for this credential"
        );
    });

    it("should allow register a new credential", async function () {
        await credentialNFT.registerCredential(credentialId, recipient.address);

        const minter = await credentialNFT.getMinter(credentialId);

        expect(minter).to.be.properAddress;
        expect(minter).to.be.equal(recipient.address);
    });

    it("should not allow register a new credential if the sender is not the owner", async function () {
        await expect(
            credentialNFT
                .connect(recipient)
                .registerCredential(credentialId, recipient.address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should not allow non-minters to mint NFTs", async function () {
        await expect(
            credentialNFT
                .connect(recipient)
                .mintNFT(credentialId, tokenURI, metadataSig)
        ).to.be.revertedWith(
            "CredentialNFT: Only the registered minter can mint NFTs for this credential"
        );
    });

    it("should not allow invalid metadata", async function () {
        const invalidSig = await recipient.signMessage(tokenURI);

        await expect(
            credentialNFT
                .connect(minter)
                .mintNFT(credentialId, tokenURI, invalidSig)
        ).to.be.revertedWith("CredentialNFT: Invalid metadata");
    });

    it("should be possible to mint with the valid metadata", async function () {
        await credentialNFT.registerCredential(credentialId, recipient.address);
        await credentialNFT
            .connect(recipient)
            .mintNFT(credentialId, tokenURI, metadataSig);
    });

    it("should return the total supply of NFTs", async function () {
        const totalSupply = await credentialNFT.totalSupply();

        await credentialNFT
            .connect(minter)
            .mintNFT(credentialId, tokenURI, metadataSig);

        assert.equal(
            await credentialNFT.totalSupply(),
            parseInt(totalSupply) + 1
        );
    });
});
