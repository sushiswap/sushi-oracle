pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { BlockVerifier } from "./BlockVerifier.sol";
import { MerklePatriciaVerifier } from "./MerklePatriciaVerifier.sol";
import { Rlp } from "./Rlp.sol";
import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";
import { UQ112x112 } from "./UQ112x112.sol";
import "hardhat/console.sol";

contract SushiOracle {
	using UQ112x112 for uint224;

	bytes32 public constant reserveTimestampSlotHash = keccak256(abi.encodePacked(uint256(8)));
	bytes32 public constant token0Slot = keccak256(abi.encodePacked(uint256(9)));
	bytes32 public constant token1Slot = keccak256(abi.encodePacked(uint256(10)));

	struct ProofData {
		bytes block;
		bytes accountProofNodesRlp;
		bytes reserveAndTimestampProofNodesRlp;
		bytes priceAccumulatorProofNodesRlp;
	}

	function getAccountStorageRoot(address uniswapV2Pair, ProofData memory proofData, bytes32 blockHash) public view returns (bytes32 storageRootHash, uint256 blockNumber, uint256 blockTimestamp) {
		bytes32 stateRoot;
		(stateRoot, blockTimestamp, blockNumber) = BlockVerifier.extractStateRootAndTimestamp(proofData.block, blockHash);
		bytes memory accountDetailsBytes = MerklePatriciaVerifier.getValueFromProof(stateRoot, keccak256(abi.encodePacked(uniswapV2Pair)), proofData.accountProofNodesRlp);
		Rlp.Item[] memory accountDetails = Rlp.toList(Rlp.toItem(accountDetailsBytes));
		return (Rlp.toBytes32(accountDetails[2]), blockNumber, blockTimestamp);
	}

	function prepareAccountDetailsBytes(address uniswapV2Pair, ProofData memory proofData, bytes32 blockHash) public view returns (Rlp.Item[][] memory items) {
		bytes32 stateRoot;
		uint256 blockNumber;
		uint256 blockTimestamp;
		(stateRoot, blockTimestamp, blockNumber) = BlockVerifier.extractStateRootAndTimestamp(proofData.block, blockHash);
		items = prepareProofData(stateRoot, keccak256(abi.encodePacked(uniswapV2Pair)), proofData.accountProofNodesRlp);
	}

	function validateAccountDetailsRlp(address uniswapV2Pair, bytes32 blockHash, Rlp.Item[][] memory items) public view returns (bytes memory accountDetailsBytes) {
		accountDetailsBytes = getValueFromProofRlp(stateRoot, keccak256(abi.encodePacked(uniswapV2Pair)), items);
	}

	// This function verifies the full block is old enough (MIN_BLOCK_COUNT), not too old (or blockhash will return 0x0) and return the proof values for the two storage slots we care about
	function verifyBlockAndExtractReserveData(IUniswapV2Pair uniswapV2Pair, bytes32 slotHash, ProofData memory proofData, bytes32 blockHash) public view returns
	(uint256 blockTimestamp, uint256 blockNumber, uint256 priceCumulativeLast, uint112 reserve0, uint112 reserve1, uint256 reserveTimestamp) {
		bytes32 storageRootHash;
		(storageRootHash, blockNumber, blockTimestamp) = getAccountStorageRoot(address(uniswapV2Pair), proofData, blockHash);
		// require (blockNumber <= block.number - minBlocksBack, "Proof does not span enough blocks");
		// require (blockNumber >= block.number - maxBlocksBack, "Proof spans too many blocks");

		priceCumulativeLast = Rlp.rlpBytesToUint256(MerklePatriciaVerifier.getValueFromProof(storageRootHash, slotHash, proofData.priceAccumulatorProofNodesRlp));
		uint256 reserve0Reserve1TimestampPacked = Rlp.rlpBytesToUint256(MerklePatriciaVerifier.getValueFromProof(storageRootHash, reserveTimestampSlotHash, proofData.reserveAndTimestampProofNodesRlp));
		reserveTimestamp = reserve0Reserve1TimestampPacked >> (112 + 112);
		reserve1 = uint112((reserve0Reserve1TimestampPacked >> 112) & (2**112 - 1));
		reserve0 = uint112(reserve0Reserve1TimestampPacked & (2**112 - 1));
	}

	function getPrice(IUniswapV2Pair uniswapV2Pair, address denominationToken, uint256 blockNum, ProofData memory proofData) public view returns (uint256 price, uint256 blockNumber) {
		// exchange = the ExchangeV2Pair. check denomination token (USE create2 check?!) check gas cost
		bool denominationTokenIs0 = true;
		if (uniswapV2Pair.token0() == denominationToken) {
			denominationTokenIs0 = true;
		} else if (uniswapV2Pair.token1() == denominationToken) {
			denominationTokenIs0 = false;
		} else {
			revert("denominationToken invalid");
		}
		return getPriceRaw(uniswapV2Pair, denominationTokenIs0, proofData, blockhash(blockNum));
	}

	function getPriceRaw(IUniswapV2Pair uniswapV2Pair, bool denominationTokenIs0, ProofData memory proofData, bytes32 blockHash) public view returns (uint256 price, uint256 blockNumber) {
		uint256 historicBlockTimestamp;
		uint256 historicPriceCumulativeLast;
		{
			// Stack-too-deep workaround, manual scope
			// Side-note: wtf Solidity?
			uint112 reserve0;
			uint112 reserve1;
			uint256 reserveTimestamp;
			(historicBlockTimestamp, blockNumber, historicPriceCumulativeLast, reserve0, reserve1, reserveTimestamp) = verifyBlockAndExtractReserveData(uniswapV2Pair, denominationTokenIs0 ? token1Slot : token0Slot, proofData, blockHash);
			uint256 secondsBetweenReserveUpdateAndHistoricBlock = historicBlockTimestamp - reserveTimestamp;
			// bring old record up-to-date, in case there was no cumulative update in provided historic block itself
			if (secondsBetweenReserveUpdateAndHistoricBlock > 0) {
				historicPriceCumulativeLast += secondsBetweenReserveUpdateAndHistoricBlock * uint(UQ112x112
					.encode(denominationTokenIs0 ? reserve0 : reserve1)
					.uqdiv(denominationTokenIs0 ? reserve1 : reserve0)
				);
			}
		}
		uint256 secondsBetweenProvidedBlockAndNow = block.timestamp - historicBlockTimestamp;
		price = (getCurrentPriceCumulativeLast(uniswapV2Pair, denominationTokenIs0) - historicPriceCumulativeLast) / secondsBetweenProvidedBlockAndNow;
		return (price, blockNumber);
	}

	function getCurrentPriceCumulativeLast(IUniswapV2Pair uniswapV2Pair, bool denominationTokenIs0) public view returns (uint256 priceCumulativeLast) {
		(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
		priceCumulativeLast = denominationTokenIs0 ? uniswapV2Pair.price1CumulativeLast() : uniswapV2Pair.price0CumulativeLast();
		uint256 timeElapsed = block.timestamp - blockTimestampLast;
		priceCumulativeLast += timeElapsed * uint(UQ112x112
			.encode(denominationTokenIs0 ? reserve0 : reserve1)
			.uqdiv(denominationTokenIs0 ? reserve1 : reserve0)
		);
	}

	function prepareProofData(bytes32 expectedRoot, bytes32 path, bytes memory proofNodesRlp) public view returns (Rlp.Item[][] memory) {
		
		Rlp.Item memory rlpParentNodes = Rlp.toItem(proofNodesRlp);
		Rlp.Item[] memory parentNodes = Rlp.toList(rlpParentNodes);
		Rlp.Item[][] memory nodes = new Rlp.Item[][](parentNodes.length);

		bytes memory currentNode;
		// Rlp.Item[] memory currentNodeList;

		bytes32 nodeKey = expectedRoot;
		uint pathPtr = 0;

		// our input is a 32-byte path, but we have to prepend a single 0 byte to that and pass it along as a 33 byte memory array since that is what getNibbleArray wants
		bytes memory nibblePath = new bytes(33);
		assembly { mstore(add(nibblePath, 33), path) }
		nibblePath = _getNibbleArray(nibblePath);

		require(path.length != 0, "empty path provided");

		currentNode = Rlp.toBytes(parentNodes[0]);

		for (uint i=0; i<parentNodes.length; i++) {
			require(pathPtr <= nibblePath.length, "Path overflow");

			nodes[i] = Rlp.toList(parentNodes[i]);

			if(nodes[i].length == 17) {
				if(pathPtr == nibblePath.length) {
					return nodes;
				}
				uint8 nextPathNibble = uint8(nibblePath[pathPtr]);
				require(nextPathNibble <= 16, "nibble too long");
				nodeKey = Rlp.toBytes32(nodes[i][nextPathNibble]);
				pathPtr += 1;
			} else if(nodes[i].length == 2) {
				pathPtr += _nibblesToTraverse(Rlp.toData(nodes[i][0]), nibblePath, pathPtr);
				// leaf node
				if(pathPtr == nibblePath.length) {
					return nodes;
				}
				//extension node
				require(_nibblesToTraverse(Rlp.toData(nodes[i][0]), nibblePath, pathPtr) != 0, "invalid extension node");

				nodeKey = Rlp.toBytes32(nodes[i][1]);
			} else {
				require(false, "unexpected length array");
			}
		}
		require(false, "not enough proof nodes");
	}

	// function prepareProofDataRlp(bytes32 expectedRoot, bytes32 path, Rlp.Item[][] memory proofData) internal pure returns (bytes memory) {
	// 	Rlp.Item memory rlpParentNodes = Rlp.toItem(proofNodesRlp);
	// 	Rlp.Item[] memory parentNodes = Rlp.toList(rlpParentNodes);

	// 	bytes memory currentNode;
	// 	Rlp.Item[] memory currentNodeList;

	// 	bytes32 nodeKey = expectedRoot;
	// 	uint pathPtr = 0;

	// 	// our input is a 32-byte path, but we have to prepend a single 0 byte to that and pass it along as a 33 byte memory array since that is what getNibbleArray wants
	// 	bytes memory nibblePath = new bytes(33);
	// 	assembly { mstore(add(nibblePath, 33), path) }
	// 	nibblePath = _getNibbleArray(nibblePath);

	// 	require(path.length != 0, "empty path provided");

	// 	currentNode = Rlp.toBytes(parentNodes[0]);

	// 	for (uint i=0; i<parentNodes.length; i++) {
	// 		require(pathPtr <= nibblePath.length, "Path overflow");

	// 		currentNode = Rlp.toBytes(parentNodes[i]);
	// 		require(nodeKey == keccak256(currentNode), "node doesn't match key");

	// 		currentNodeList = Rlp.toList(parentNodes[i]);

	// 		if(currentNodeList.length == 17) {
	// 			if(pathPtr == nibblePath.length) {
	// 				return Rlp.toData(currentNodeList[16]);
	// 			}

	// 			uint8 nextPathNibble = uint8(nibblePath[pathPtr]);
	// 			require(nextPathNibble <= 16, "nibble too long");
	// 			nodeKey = Rlp.toBytes32(currentNodeList[nextPathNibble]);
	// 			pathPtr += 1;
	// 		} else if(currentNodeList.length == 2) {
	// 			pathPtr += _nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr);
	// 			// leaf node
	// 			if(pathPtr == nibblePath.length) {
	// 				return Rlp.toData(currentNodeList[1]);
	// 			}
	// 			//extension node
	// 			require(_nibblesToTraverse(Rlp.toData(currentNodeList[0]), nibblePath, pathPtr) != 0, "invalid extension node");

	// 			nodeKey = Rlp.toBytes32(currentNodeList[1]);
	// 		} else {
	// 			require(false, "unexpected length array");
	// 		}
	// 	}
	// 	require(false, "not enough proof nodes");
	// }

	// function _nibblesToTraverse(bytes memory encodedPartialPath, bytes memory path, uint pathPtr) private pure returns (uint) {
	// 	uint len;
	// 	// encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
	// 	// and slicedPath have elements that are each one hex character (1 nibble)
	// 	bytes memory partialPath = _getNibbleArray(encodedPartialPath);
	// 	bytes memory slicedPath = new bytes(partialPath.length);

	// 	// pathPtr counts nibbles in path
	// 	// partialPath.length is a number of nibbles
	// 	for(uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
	// 		byte pathNibble = path[i];
	// 		slicedPath[i-pathPtr] = pathNibble;
	// 	}

	// 	if(keccak256(partialPath) == keccak256(slicedPath)) {
	// 		len = partialPath.length;
	// 	} else {
	// 		len = 0;
	// 	}
	// 	return len;
	// }

		// bytes byteArray must be hp encoded
	function _getNibbleArray(bytes memory byteArray) private pure returns (bytes memory) {
		bytes memory nibbleArray;
		if (byteArray.length == 0) return nibbleArray;

		uint8 offset;
		uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,byteArray));
		if(hpNibble == 1 || hpNibble == 3) {
			nibbleArray = new bytes(byteArray.length*2-1);
			byte oddNibble = _getNthNibbleOfBytes(1,byteArray);
			nibbleArray[0] = oddNibble;
			offset = 1;
		} else {
			nibbleArray = new bytes(byteArray.length*2-2);
			offset = 0;
		}

		for(uint i=offset; i<nibbleArray.length; i++) {
			nibbleArray[i] = _getNthNibbleOfBytes(i-offset+2,byteArray);
		}
		return nibbleArray;
	}

	function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (byte) {
		return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
	}
}
