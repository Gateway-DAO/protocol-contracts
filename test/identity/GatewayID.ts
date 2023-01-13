import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("GatewayID", () => {
  let id: Contract;
  let masterWallet: Signer;
  let signerWallet: Signer;
  let memberWallet: Signer;

  before(async () => {
    masterWallet = (await ethers.getSigners())[0];
    signerWallet = (await ethers.getSigners())[1];
    memberWallet = (await ethers.getSigners())[2];
  });

  beforeEach(async () => {
    const GatewayID = await ethers.getContractFactory(
        "GatewayID"
      );
    id = await GatewayID.deploy(masterWallet.getAddress(), signerWallet.getAddress());
  });

  it("should have the correct master wallet", async () => {
    expect(await id.getMasterWallet()).to.equal(await masterWallet.getAddress());
  });

  it("should add an EVM wallet correctly", async () => {
    let tx = await id.addEVMWallet(await memberWallet.getAddress());
    expect(await id.noOfWallets()).to.equal(3);
  });

  it("should not allow adding an EVM wallet by a non-owner", async () => {
    const tx = id.connect(signerWallet).addEVMWallet(await memberWallet.getAddress());
    await expect(tx).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should not allow adding a duplicate EVM wallet", async () => {
    await id.addEVMWallet(await memberWallet.getAddress());
    const tx = id.addEVMWallet(await memberWallet.getAddress());
    await expect(tx).to.be.revertedWith("GatewayID: Wallet already exists");
  });
});