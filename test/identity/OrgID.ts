import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";

describe("OrgID", () => {
    let credential: Contract;
    let dataModel: Contract;
    let nftFactory: Contract;
    let registry: Contract;

    let contract: Contract;

    before(async () => {
        // Deploy contracts
        const Credential = await ethers.getContractFactory(
            "CredentialContract"
        );
        credential = await Credential.deploy();

        const DataModel = await ethers.getContractFactory("DataModel");
        dataModel = await DataModel.deploy();

        const Registry = await ethers.getContractFactory("GatewayIDRegistry");
        registry = await Registry.deploy(credential.address, dataModel.address);

        const NFTFactory = await ethers.getContractFactory(
            "CredentialNFTFactory"
        );
        nftFactory = await NFTFactory.deploy(registry.address);
    });

    beforeEach(async () => {
        const [owner, signer1, signer2] = await ethers.getSigners();

        const OrgID = await ethers.getContractFactory("OrgID");
        contract = await OrgID.deploy(
            owner.getAddress(),
            [signer1.getAddress(), signer2.getAddress()],
            nftFactory.address,
            credential.address,
            dataModel.address
        );
    });

    it("should allow owner to add an authorized member", async function () {
        const [owner, signer1, signer2, member] = await ethers.getSigners();
        await contract.addMember(member.address, { from: owner.address });
        expect(await contract.members(member.address)).to.equal(true);
    });

    it("should not allow non-owner to add an authorized member", async function () {
        const [owner, signer1, signer2, member, nonOwner] =
            await ethers.getSigners();
        await expect(
            contract.connect(nonOwner).addMember(member.address, { from: nonOwner.address })
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should allow owner to remove an authorized member", async function () {
        const [owner, signer1, signer2, member] = await ethers.getSigners();
        await contract.addMember(member.address, { from: owner.address });
        await contract.removeMember(member.address, { from: owner.address });
        expect(await contract.members(member.address)).to.equal(false);
    });

    it("should not allow non-owner to remove an authorized member", async function () {
        const [owner, signer1, signer2, member, nonOwner] =
            await ethers.getSigners();
        await contract.addMember(member.address, { from: owner.address });
        await expect(
            contract.connect(nonOwner).removeMember(member.address, { from: nonOwner.address })
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});
