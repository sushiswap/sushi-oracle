import { ethers } from "hardhat";
import { Signer } from "ethers";
import { getStorageAt, getProof, getBlockByNumber, getBlockHashByNumber, BlockHash } from "../../library/source/demo";
import * as OracleSdk from '@keydonix/uniswap-oracle-sdk';

describe("Token", function () {
  let accounts: Signer[];
  let sushiOracle;

  before(async function () {
    accounts = await ethers.getSigners();
    // const SushiOracle = await ethers.getContractFactory("SushiOracle");
    // sushiOracle = await SushiOracle.deploy();

    // await sushiOracle.deployed();
  });

  it("should do something right", async function () {
    // Do something with the accounts
    const JSON_RPC = 'https://eth-mainnet.alchemyapi.io/v2/akJ4Iz9CBxJ6HduDFaNUwwg1igCzQmDk'
    const provider = new ethers.providers.JsonRpcProvider(JSON_RPC)

    const address = BigInt("0xbb2b8038a1640196fbe3e38816f3e67cba72d940")
    const token0 = BigInt("0x2260fac5e5542a773aa44fbcfedf7c193bc2c599")
    const blockNumber = BigInt("12680299")
    const proof = await OracleSdk.getProof(getStorageAt, getProof, getBlockByNumber, address, token0, blockNumber)
    const block = await getBlockHashByNumber(blockNumber)
  
    const abi = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"uniswapV2Pair\",\"type\":\"address\"},{\"components\":[{\"internalType\":\"bytes\",\"name\":\"block\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"accountProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"reserveAndTimestampProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"priceAccumulatorProofNodesRlp\",\"type\":\"bytes\"}],\"internalType\":\"struct SushiOracle.ProofData\",\"name\":\"proofData\",\"type\":\"tuple\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"getAccountStorageRoot\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"storageRootHash\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"blockNumber\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"blockTimestamp\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"contract IUniswapV2Pair\",\"name\":\"uniswapV2Pair\",\"type\":\"address\"},{\"internalType\":\"bool\",\"name\":\"denominationTokenIs0\",\"type\":\"bool\"}],\"name\":\"getCurrentPriceCumulativeLast\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"priceCumulativeLast\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"contract IUniswapV2Pair\",\"name\":\"uniswapV2Pair\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"denominationToken\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"blockNum\",\"type\":\"uint256\"},{\"components\":[{\"internalType\":\"bytes\",\"name\":\"block\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"accountProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"reserveAndTimestampProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"priceAccumulatorProofNodesRlp\",\"type\":\"bytes\"}],\"internalType\":\"struct SushiOracle.ProofData\",\"name\":\"proofData\",\"type\":\"tuple\"}],\"name\":\"getPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"blockNumber\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"contract IUniswapV2Pair\",\"name\":\"uniswapV2Pair\",\"type\":\"address\"},{\"internalType\":\"bool\",\"name\":\"denominationTokenIs0\",\"type\":\"bool\"},{\"components\":[{\"internalType\":\"bytes\",\"name\":\"block\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"accountProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"reserveAndTimestampProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"priceAccumulatorProofNodesRlp\",\"type\":\"bytes\"}],\"internalType\":\"struct SushiOracle.ProofData\",\"name\":\"proofData\",\"type\":\"tuple\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"getPriceRaw\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"blockNumber\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"reserveTimestampSlotHash\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"token0Slot\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"token1Slot\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"contract IUniswapV2Pair\",\"name\":\"uniswapV2Pair\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"slotHash\",\"type\":\"bytes32\"},{\"components\":[{\"internalType\":\"bytes\",\"name\":\"block\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"accountProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"reserveAndTimestampProofNodesRlp\",\"type\":\"bytes\"},{\"internalType\":\"bytes\",\"name\":\"priceAccumulatorProofNodesRlp\",\"type\":\"bytes\"}],\"internalType\":\"struct SushiOracle.ProofData\",\"name\":\"proofData\",\"type\":\"tuple\"},{\"internalType\":\"bytes32\",\"name\":\"blockHash\",\"type\":\"bytes32\"}],\"name\":\"verifyBlockAndExtractReserveData\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"blockTimestamp\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"blockNumber\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"priceCumulativeLast\",\"type\":\"uint256\"},{\"internalType\":\"uint112\",\"name\":\"reserve0\",\"type\":\"uint112\"},{\"internalType\":\"uint112\",\"name\":\"reserve1\",\"type\":\"uint112\"},{\"internalType\":\"uint256\",\"name\":\"reserveTimestamp\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]"
    const sushiOracle = new ethers.Contract("0x941842953733145bEF4f6EEFa20d5B1A68c3545B", abi, provider)
    const result = await sushiOracle.getPriceRaw(ethers.utils.hexValue(address), true, proof, ethers.utils.hexValue(block.hash))
    console.log(result)
  });
});
