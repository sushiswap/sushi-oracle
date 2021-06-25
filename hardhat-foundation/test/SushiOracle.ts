import { ethers } from "hardhat";
import { Signer } from "ethers";
import { getStorageAt, getProof, getBlockByNumber, getBlockHashByNumber, BlockHash } from "../../library/source/demo";
import * as OracleSdk from '@keydonix/uniswap-oracle-sdk';

describe("Token", function () {
  let accounts: Signer[];

  beforeEach(async function () {
    accounts = await ethers.getSigners();
  });

  it("should do something right", async function () {
    // Do something with the accounts
    const SushiOracle = await ethers.getContractFactory("SushiOracle");
    const sushiOracle = await SushiOracle.deploy();

    await sushiOracle.deployed();

    const JSON_RPC = 'https://eth-mainnet.alchemyapi.io/v2/akJ4Iz9CBxJ6HduDFaNUwwg1igCzQmDk'
    const provider = new ethers.providers.JsonRpcProvider(JSON_RPC)

    const address = BigInt("0xbb2b8038a1640196fbe3e38816f3e67cba72d940")
    const token0 = BigInt("0x2260fac5e5542a773aa44fbcfedf7c193bc2c599")
    const blockNumber = BigInt("12680299")
    const proof = await OracleSdk.getProof(getStorageAt, getProof, getBlockByNumber, address, token0, blockNumber)
    const block = await getBlockHashByNumber(blockNumber)
    
    // const result = await sushiOracle.getPriceRaw(ethers.utils.hexValue(address), true, proof, ethers.utils.hexValue(block.hash))
    const result = await sushiOracle.prepareAccountDetailsBytes(ethers.utils.hexValue(address), proof, ethers.utils.hexValue(block.hash))
    console.log(result)
  });
});
