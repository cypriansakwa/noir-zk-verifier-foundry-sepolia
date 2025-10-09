// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../Verifier.sol"; // HonkVerifier

contract VerifyProofTest is Test {
    HonkVerifier public verifier;
    bytes32[] public publicInputs = new bytes32[](2);

    function setUp() public {
        // deployed address from Anvil
        verifier = HonkVerifier(payable(0x3e96C09d2361d27D577f18BD20Aa5A86CB313AB0));

        // populate public inputs
        publicInputs[0] = bytes32(uint256(3));
        publicInputs[1] = bytes32(uint256(6));
    }

    function testVerifyProof() public {
        bytes memory proof = vm.readFileBinary("../circuits/target/proof");
        bool result = verifier.verify(proof, publicInputs);
        assert(result);
    }
}
