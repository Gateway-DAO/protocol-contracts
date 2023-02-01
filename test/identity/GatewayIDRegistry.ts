import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("GatewayIDRegistry", function () {
  let signers: SignerWithAddress[];
  let registry: Contract;
  const USERNAME = ethers.utils.formatBytes32String("test");
  const NON_EXISTANT_USERNAME = ethers.utils.formatBytes32String("nonexistant");

  before(async function () {
    signers = await ethers.getSigners();
    const GatewayIDRegistry = await ethers.getContractFactory(
      "GatewayIDRegistry"
    );
    registry = await GatewayIDRegistry.deploy();
    await registry.deployed();
  });

  it("should deploy a new UserID contract and associate it with a provided username", async function () {
    const UserID = await ethers.getContractFactory("UserID");

    let tx = await registry.deployIdentity(
      await signers[0].getAddress(),
      await signers[1].getAddress(),
      USERNAME
    );
    let identityAddress = await registry.getIdentity(USERNAME);
    let identity = await UserID.attach(identityAddress);
    let masterWallet = await identity.getMasterWallet();

    expect(masterWallet).to.equal(await signers[0].getAddress());
  });

  it("should not allow deploying a UserID contract with a duplicate username", async function () {
    let id2 = registry.deployIdentity(
      await signers[2].getAddress(),
      await signers[3].getAddress(),
      USERNAME
    );

    await expect(id2).to.be.revertedWith(
      "GatewayIDRegistry: Username already exists"
    );
  });

  it("should return the address of the UserID contract associated with a provided username", async function () {
    let result = await registry.getIdentity(USERNAME);

    expect(result).to.be.properAddress;
  });

  it("should return the address of the master wallet for a UserID contract associated with a provided username", async () => {
    let masterWallet = await registry.getMasterWallet(USERNAME);

    expect(masterWallet).to.equal(await signers[0].getAddress());
  });

  it("should return false for a non-existent username", async () => {
    let exists = await registry.usernameExists(NON_EXISTANT_USERNAME);

    expect(exists).to.equal(false);
  });

  it("should return true for an existent username", async () => {
    let exists = await registry.usernameExists(USERNAME);

    expect(exists).to.equal(true);
  });
});
