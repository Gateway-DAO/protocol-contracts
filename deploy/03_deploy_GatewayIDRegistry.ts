import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const credential = await hre.deployments.get("CredentialContract");
    const dataModel = await hre.deployments.get("DataModel");

    // proxy only in non-live network (localhost and hardhat network) enabling HCR (Hot Contract Replacement)
    // in live network, proxy is disabled and constructor is invoked
    await deploy("GatewayIDRegistry", {
        from: deployer,
        args: [credential.address, dataModel.address],
        log: true,
        autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    });
};

export default func;
func.id = "deploy_GatewayIDRegistry"; // id required to prevent reexecution
func.tags = ["GatewayIDRegistry"];
