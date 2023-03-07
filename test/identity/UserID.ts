import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect, assert } from "chai";

enum Type {
    EVM,
    Solana,
}

function addressToBytes32(address: string) {
    return ethers.utils.hexZeroPad(ethers.utils.hexlify(address), 32);
}

describe("UserID", () => {
    let contract: Contract;
    let registry: Contract;

    let w1: Signer;
    let w2: Signer;
    let w3: Signer;
    let executor: Signer;
    let solana: string;

    before(async () => {
        w1 = (await ethers.getSigners())[0];
        w2 = (await ethers.getSigners())[1];
        w3 = (await ethers.getSigners())[2];
        executor = (await ethers.getSigners())[3];
        solana = "BZGPpxbSYH6B4hr7eXDv4s5LULZv24GB57JzqZd5Qq6D";

        const Registry = await ethers.getContractFactory("GatewayIDRegistry");
        registry = await Registry.deploy();
        await registry.addExecutor(await executor.getAddress());
    });

    beforeEach(async () => {
        const UserID = await ethers.getContractFactory("UserID");
        contract = await UserID.deploy(
            [
                {
                    public_key: addressToBytes32(await w1.getAddress()),
                    wallet_type: Type.EVM,
                },
            ],
            registry.address
        );
    });

    it("Should be able to create a new UserID", async () => {
        const id = await contract.getId(
            addressToBytes32(await w1.getAddress()),
            Type.EVM
        );

        const wallet = await contract.wallets(id);

        expect(wallet.public_key).to.equal(
            addressToBytes32(await w1.getAddress())
        );
        expect(wallet.wallet_type).to.equal(Type.EVM);
    });

    it("Should be able to add an EVM wallet", async () => {
        const tx = await contract
            .connect(w1)
            .addWallet(addressToBytes32(await w2.getAddress()), Type.EVM);

        const wallet = await contract.wallets(
            await contract.getId(
                addressToBytes32(await w2.getAddress()),
                Type.EVM
            )
        );

        expect(wallet.public_key).to.equal(
            addressToBytes32(await w2.getAddress())
        );
        expect(wallet.wallet_type).to.equal(Type.EVM);
    });

    it("Should be able to add a Solana wallet", async () => {
        const tx = await contract.connect(w1).addWallet(solana, Type.Solana);

        const wallet = await contract.wallets(
            await contract.getId(solana, Type.Solana)
        );

        expect(wallet.public_key).to.equal(solana);
        expect(wallet.wallet_type).to.equal(Type.Solana);
    });

    it("Should be able to remove an EVM wallet", async () => {
        await contract
            .connect(w1)
            .addWallet(addressToBytes32(await w2.getAddress()), Type.EVM);
        const tx = await contract
            .connect(w1)
            .removeWallet(addressToBytes32(await w2.getAddress()), Type.EVM);

        const wallet = await contract.wallets(
            await contract.getId(
                addressToBytes32(await w2.getAddress()),
                Type.EVM
            )
        );

        expect(wallet.public_key).to.equal(
            addressToBytes32(ethers.constants.AddressZero)
        );
    });

    // it("Should only allow master wallet to add, remove, or update a wallet", async () => {
    //     await contract
    //         .connect(w1)
    //         .addEVMWallet(await w3.getAddress(), Type.EVM);

    //     try {
    //         await contract
    //             .connect(w2)
    //             .addEVMWallet(await w3.getAddress(), Type.EVM);
    //         assert.fail();
    //     } catch (err: any) {
    //         expect(err.reason).to.equal("UserID: Not master wallet");
    //     }

    //     try {
    //         await contract.connect(w2).removeEVMWallet(await w1.getAddress());
    //         assert.fail();
    //     } catch (err: any) {
    //         expect(err.reason).to.equal("UserID: Not master wallet");
    //     }
    // });
});
