import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    // get factory address from previous deployment
    const registry = await hre.deployments.get("GatewayIDRegistry");

    // proxy only in non-live network (localhost and hardhat network) enabling HCR (Hot Contract Replacement)
    // in live network, proxy is disabled and constructor is invoked
    await deploy("CredentialNFTFactory", {
        from: deployer,
        args: [registry.address],
        log: true,
        autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    });

    const contract = await ethers.getContractAt(
        "GatewayIDRegistry",
        registry.address
    );

    // set factory address in registry
    await contract.setFactoryAddress(
        (
            await hre.deployments.get("CredentialNFTFactory")
        ).address
    );
};

export default func;
func.id = "deploy_CredentialNFT_factory"; // id required to prevent reexecution
func.tags = ["CredentialNFTFactory"];
