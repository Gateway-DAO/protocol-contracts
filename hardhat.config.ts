import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import { getDeployerAccount, getNodeURL } from "./utils/network";

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            outputSelection: {
                "*": {
                    "*": ["metadata", "evm.bytecode"],
                    "": ["ast"],
                },
            },
            metadata: {
                bytecodeHash: "none",
            },
        },
    },
    namedAccounts: {
        deployer: {
            default: getDeployerAccount(),
        },
    },
    networks: {
        goerli: {
            url: getNodeURL("goerli"),
            accounts: [process.env.PRIVATE_KEY as string],
        },
        polygon: {
            url: getNodeURL("polygon"),
            accounts: [process.env.PRIVATE_KEY as string],
        },
        mumbai: {
            url: getNodeURL("mumbai"),
            accounts: [process.env.PRIVATE_KEY as string],
        },
    },
};

export default config;
