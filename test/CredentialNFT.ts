import { Contract, Signer } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("CredentialNFTContract", () => {
    let credentialNFT: Contract;
    let signers: SignerWithAddress[];
    let issuer: SignerWithAddress;
    let minter: SignerWithAddress;
    let anotherMinter: SignerWithAddress;
    let credentialId: string;
    let metadataUrl: string;
    let metadataSig: string;

    beforeEach(async function () {
        const CredentialNFT = await ethers.getContractFactory("CredentialNFT");
        signers = await ethers.getSigners();
        issuer = await signers[0];
        minter = await signers[1];
        anotherMinter = await signers[2];

        credentialNFT = await CredentialNFT.deploy("CredentialNFT", "GCRED");
        await credentialNFT.deployed();

        credentialId = "1234567890";
        metadataUrl = "https://example.com/metadata";
        metadataSig = await issuer.signMessage(metadataUrl);
    });

    // it("should allow the issuer to set a minter", async function () {
    //     await credentialNFT.setMinter(credentialId, minter.address);
    //     expect(await credentialNFT.credentialToMinter(credentialId)).to.equal(
    //         minter.address
    //     );
    // });

    it("should prevent a non-owner from setting a minter", async function () {
        await expect(
            credentialNFT
                .connect(minter)
                .setMinter(credentialId, anotherMinter.address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should allow the issuer to remove a minter", async function () {
        await credentialNFT.setMinter(credentialId, minter.address);
        expect(await credentialNFT.removeMinter(credentialId, minter.address))
            .to.emit(credentialNFT, "MinterRemoved")
            .withArgs(credentialId, minter.address);
    });

    it("should prevent a non-issuer from removing a minter", async function () {
        await credentialNFT.setMinter(credentialId, minter.address);
        const removeMinter = credentialNFT
            .connect(minter)
            .removeMinter(credentialId, minter.address);

        await expect(removeMinter).to.be.revertedWith(
            "Ownable: caller is not the owner"
        );
    });

    it("should allow a caller to register a credential", async function () {
        const registerCredential = await credentialNFT.registerCredential(
            credentialId,
            metadataUrl,
            metadataSig
        );
        expect(registerCredential)
            .to.emit(credentialNFT, "CredentialRegistered")
            .withArgs(credentialId, minter.address);
    });

    it("should prevent a caller from registering a credential with an invalid signature", async function () {
        const invalidSig = await anotherMinter.signMessage(metadataUrl);
        const invalidRegisteredCredential = credentialNFT.registerCredential(
            credentialId,
            metadataUrl,
            invalidSig
        );
        await expect(invalidRegisteredCredential).to.be.revertedWith(
            "CredentialNFT: Invalid metadata signature"
        );
    });

    // it("should prevent a caller from registering a credential with a zero address minter", async function () {
    //     const invalidAddressonRegisteredCredential =
    //         credentialNFT.registerCredential(
    //             credentialId,
    //             metadataUrl,
    //             metadataSig,
    //             { from: 0x0 }
    //         );

    //     await expect(invalidAddressonRegisteredCredential).to.be.revertedWith(
    //         "CredentialNFT: Minter cannot be the zero address"
    //     );
    // });

    // it("should prevent a caller from registering a credential with an already registered minter", async function () {
    //     await credentialNFT.setMinter(credentialId, minter.address);
    //     await expect(
    //         credentialNFT.registerCredential(
    //             credentialId,
    //             metadataUrl,
    //             metadataSig
    //         )
    //     ).to.be.revertedWith(
    //         "CredentialNFT: Minter is already registered for this credential"
    //     );
    // });

    // it("should allow a caller to mint an NFT for a valid credential", async function () {
    //     await credentialNFT.registerCredential(
    //         credentialId,
    //         metadataUrl,
    //         metadataSig
    //     );
    //     await credentialNFT.setMinter(credentialId, minter.address);
    //     const receipt = await credentialNFT
    //         .connect(minter)
    //         .mintNFT(credentialId);
    //     const tokenId = receipt.events[0].args.tokenId;
    //     expect(await credentialNFT.issuerOf(tokenId)).to.equal(minter.address);
    // });

    it("should prevent a caller from minting an NFT for an invalid credential", async function () {
        await credentialNFT.registerCredential(
            credentialId,
            metadataUrl,
            metadataSig
        );
        await expect(
            credentialNFT.connect(minter).mintNFT(credentialId)
        ).to.be.revertedWith(
            "CredentialNFT: Only the registered minter can mint NFTs for this credential"
        );
    });

    it("should prevent a non-minter from minting an NFT for a credential", async function () {
        await credentialNFT.registerCredential(
            credentialId,
            metadataUrl,
            metadataSig
        );
        await credentialNFT.setMinter(credentialId, minter.address);
        await expect(
            credentialNFT.connect(anotherMinter).mintNFT(credentialId)
        ).to.be.revertedWith(
            "CredentialNFT: Only the registered minter can mint NFTs for this credential"
        );
    });

    it("should prevent a caller from minting an NFT for an unregistered credential", async function () {
        await expect(
            credentialNFT.connect(minter).mintNFT(credentialId)
        ).to.be.revertedWith(
            "CredentialNFT: Only the registered minter can mint NFTs for this credential"
        );
    });

    // it("should prevent a caller from minting multiple NFTs for the same credential", async function () {
    //     await credentialNFT.registerCredential(
    //         credentialId,
    //         metadataUrl,
    //         metadataSig
    //     );
    //     await credentialNFT.setMinter(credentialId, minter.address);
    //     await credentialNFT.connect(minter).mintNFT(credentialId);
    //     await expect(
    //         credentialNFT.connect(minter).mintNFT(credentialId)
    //     ).to.be.revertedWith("ERC721: token already minted");
    // });
});
