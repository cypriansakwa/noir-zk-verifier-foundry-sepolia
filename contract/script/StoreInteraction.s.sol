// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";

interface IHonkVerifierWithRecord {
    function verifyAndStore(bytes calldata proof, bytes32[] calldata publicInputs) external returns (bool);
}

contract StoreInteraction is Script {
    function run() external {
        // Load your private key from env or hardcode (if testing)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // ✅ Address of the deployed HonkVerifierWithRecord contract
        address verifierAddress = 0x7531f5487c8B1e8e832d74FDB4Fa5214FE21a781;

        // ✅ Load Noir proof file
        bytes memory proof = vm.readFileBinary("../circuits/target/proof");

        // ✅ Prepare your public inputs (adjust as per your circuit)
        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = bytes32(uint256(3));
        publicInputs[1] = bytes32(uint256(6));

        // ✅ Call verifyAndStore() — this sends a transaction
        bool result = IHonkVerifierWithRecord(verifierAddress).verifyAndStore(proof, publicInputs);

        console.log("On-chain verification result:", result);

        vm.stopBroadcast();
    }
}
