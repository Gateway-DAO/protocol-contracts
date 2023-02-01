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
  let master_pkh: string;
  let signer_pkh: string;
  let other_pkh: string;

  before(async () => {
    master = (await ethers.getSigners())[0];
    signer = (await ethers.getSigners())[1];
    other = (await ethers.getSigners())[2];

    master_pkh =
      "0x0000000000000000000000000000000000000000000000000000000000000001";
    signer_pkh =
      "0x0000000000000000000000000000000000000000000000000000000000000002";
    other_pkh =
      "0x0000000000000000000000000000000000000000000000000000000000000003";
  });

  beforeEach(async () => {
    const UserID = await ethers.getContractFactory("UserID");
    contract = await UserID.deploy(master.getAddress(), signer.getAddress());
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
      .addEVMWallet(master_pkh, Type.EVM, { from: master });
    const tx = await contract.removeEVMWallet(master_pkh, { from: master });
    expect(tx.logs[0].args.pkh).to.equal(master_pkh);
    expect(tx.logs[0].args.wallet).to.equal(master.getAddress());
    expect(tx.logs[0].args.wallet_type).to.equal(Type.EVM);
    const wallet = await contract.wallets(
      ethers.utils.solidityPack(
        ["bytes32", "address"],
        [master_pkh, await master.getAddress()]
      )
    );
    expect(wallet.wallet).to.equal(ethers.constants.AddressZero);
  });

  it("Should be able to update a wallet", async () => {
    await contract.addEVMWallet(master_pkh, Type.EVM, { from: master });
    const tx = await contract.updateWallet(master_pkh, Type.Email, {
      from: master,
    });
    expect(tx.logs[0].args.pkh).to.equal(master_pkh);
    expect(tx.logs[0].args.wallet).to.equal(await master.getAddress());
    expect(tx.logs[0].args.wallet_type).to.equal(Type.Email);
    const wallet = await contract.wallets(
      ethers.utils.solidityPack(
        ["bytes32", "address"],
        [master_pkh, await master.getAddress()]
      )
    );
    expect(wallet.wallet_type).to.equal(Type.Email);
  });

  it("Should only allow master wallet to add, remove, or update a wallet", async () => {
    await contract.addEVMWallet(master_pkh, Type.EVM, { from: master });

    try {
      await contract.connect(signer).addEVMWallet(signer_pkh, Type.EVM);
      assert.fail();
    } catch (err: any) {
      expect(err.reason).to.equal("UserID: Not master wallet");
    }

    try {
      await contract.connect(signer).removeEVMWallet(master_pkh);
      assert.fail();
    } catch (err: any) {
      expect(err.reason).to.equal("UserID: Not master wallet");
    }
  });

  it("Should only allow member wallets to access certain functions", async () => {
    await contract.addEVMWallet(master_pkh, Type.EVM, { from: master });
    await contract.addEVMWallet(signer_pkh, Type.EVM, { from: signer });
    await contract.addEVMWallet(other_pkh, Type.EVM, { from: other });
    try {
      await contract.functionOnlyForMembers({ from: other });
      assert.fail();
    } catch (err: any) {
      expect(err.reason).to.equal("UserID: Not a member");
    }
  });
});
