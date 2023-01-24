import 'dotenv/config';
import { ethers } from 'ethers';

/**
 * It returns the address of the account that will deploy the contract
 * @returns The address of the deployer account.
 */
export function getDeployerAccount(): string {
    const PRIVATE_KEY = process.env.PRIVATE_KEY;

    if (!PRIVATE_KEY) {
        throw new Error('PRIVATE_KEY is not defined');
    }

    const account = new ethers.Wallet(PRIVATE_KEY);

    return account.address;
}

/**
 * It takes a network name as a parameter and returns the URL of the node for that network
 * @param {string} network - The network you want to connect to.
 * @returns The URL of the node.
 */
export function getNodeURL(network: string): string {
    const URL = process.env[network.toUpperCase() + '_NODE'];

    if (!URL) {
        throw new Error('URL is not defined');
    }

    return URL;
}