import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect, assert } from "chai";

enum Type {
  EVM,
  Email,
  Solana,
}

describe("UserID", () => {
  let contract: Contract;
  let master: Signer;
  let signer: Signer;
  let other: Signer;
  let solana: string;

  before(async () => {
    master = (await ethers.getSigners())[0];
    signer = (await ethers.getSigners())[1];
    other = (await ethers.getSigners())[2];
    solana = "BZGPpxbSYH6B4hr7eXDv4s5LULZv24GB57JzqZd5Qq6D";
  });

  beforeEach(async () => {
    const UserID = await ethers.getContractFactory("UserID");
    contract = await UserID.deploy(master.getAddress(), signer.getAddress());
  });

  it("Should be able to create a new UserID", async () => {
    expect(await contract.getMasterWallet()).to.equal(await master.getAddress());
    expect(await contract.noOfWallets()).to.equal(2);
  });

  it("Should be able to add a wallet", async () => {
    const tx = await contract
      .connect(master)
      .addEVMWallet(await other.getAddress());

    const wallet = await contract.wallets[
      ethers.utils.solidityPack(
        ["bytes32", "address"],
        [ethers.utils.formatBytes32String("0x0"), await other.getAddress()]
      )
    ];
    expect(wallet.idx).to.equal(1);
    expect(wallet.wallet).to.equal(await other.getAddress());
    expect(wallet.pkh).to.equal(ethers.constants.AddressZero);
    expect(wallet.wallet_type).to.equal(Type.EVM);
    expect(wallet.is_master).to.be.true;
    expect(wallet.is_signer).to.be.false;
  });

  it("Should be able to remove a wallet", async () => {
    await contract
      .connect(master)
      .addEVMWallet(await other.getAddress(), Type.EVM);
    const tx = await contract
      .connect(master)
      .removeEVMWallet(await other.getAddress());

    expect(tx.logs[0].args.pkh).to.equal(await other.getAddress());
    expect(tx.logs[0].args.wallet).to.equal(master.getAddress());
    expect(tx.logs[0].args.wallet_type).to.equal(Type.EVM);
    const wallet = await contract.wallets(
      ethers.utils.solidityPack(
        ["bytes32", "address"],
        [ethers.utils.formatBytes32String("0x0"), await master.getAddress()]
      )
    );
    expect(wallet.wallet).to.equal(ethers.constants.AddressZero);
  });

  it("Should only allow master wallet to add, remove, or update a wallet", async () => {
    await contract
      .connect(master)
      .addEVMWallet(await other.getAddress(), Type.EVM);

    try {
      await contract
        .connect(signer)
        .addEVMWallet(await other.getAddress(), Type.EVM);
      assert.fail();
    } catch (err: any) {
      expect(err.reason).to.equal("UserID: Not master wallet");
    }

    try {
      await contract.connect(signer).removeEVMWallet(await master.getAddress());
      assert.fail();
    } catch (err: any) {
      expect(err.reason).to.equal("UserID: Not master wallet");
    }
  });
});
