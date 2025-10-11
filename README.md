# 🧠 Interacting with On-Chain Noir ZK Verifiers Using Foundry & Sepolia

## Overview

This repository demonstrates how to deploy, interact with, and verify **Noir Zero-Knowledge (ZK) proofs** on-chain using **Foundry** and the **Ethereum Sepolia** testnet.

You’ll learn how to:

- Interact with deployed Solidity verifier contracts for Noir proofs.  
- Differentiate between read-only (local) and on-chain write interactions.  
- Record and audit verification results on-chain.  

---

## 🚀 1. Create a Foundry Script

**File:** `script/Interact.s.sol`

This script loads a Noir proof generated via `bb prove` and calls the deployed contract’s `verify()` function.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HonkVerifier} from "../Verifier.sol";

contract InteractHonkVerifier is Script {
    address constant VERIFIER_ADDRESS = 0x3e96C09d2361d27D577f18BD20Aa5A86CB313AB0;

    function run() external {
        vm.startBroadcast();
        HonkVerifier verifier = HonkVerifier(VERIFIER_ADDRESS);

        bytes memory proof = vm.readFileBinary("../circuits/target/proof");

        bytes32[2] memory publicInputs;
        publicInputs[0] = bytes32(uint256(3));
        publicInputs[1] = bytes32(uint256(6));

        bool result = verifier.verify(proof, publicInputs);
        console.log("Verification result:", result);
    }
}
```
✅ **Tip:** Replace the `VERIFIER_ADDRESS` with your own deployed verifier contract address when running the script.

---

## 🧩 2. Run the Script

Load your environment and execute:

```bash
source .env
forge script script/Interact.s.sol:InteractHonkVerifier \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast -vvvv
```
✅ Verification result: true → Proof is valid ❌ Verification result: false → Proof invalid ⚖️ 3. Read vs Write on Blockchain Type Description Example Gas Read (view/pure) No state change verify() ❌ Write (transaction) Updates state on-chain verifyAndStore() ✅ 💡 Using Foundry’s verify() is equivalent to using Etherscan’s “Read Contract” tab — but fully automated. 🪶 4. Storing Verification On-Chain File: HonkVerifierWithRecord.sol Extends your existing verifier to persist the latest verification result and emit an event for audit. // SPDX-License-Identifier: MIT pragma solidity ^0.8.17; import "./Verifier.sol"; /// @title HonkVerifierWithRecord /// @notice Extends HonkVerifier to persist verification results contract HonkVerifierWithRecord is HonkVerifier { bool public lastVerification; bytes32[] public lastPublicInputs; event ProofVerified(bool result); function verifyAndStore(bytes calldata proof, bytes32[] calldata publicInputs) external returns (bool result) { result = verify(proof, publicInputs); lastVerification = result; delete lastPublicInputs; for (uint256 i = 0; i < publicInputs.length; i++) { lastPublicInputs.push(publicInputs[i]); } emit ProofVerified(result); } } 🔧 5. Deploy on Sepolia forge build forge create ./HonkVerifierWithRecord.sol:HonkVerifierWithRecord --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv Then verify your contract on Sepolia Etherscan: Match compiler version Upload all .sol files Confirm ✅ verification success 🧠 6. Store Verification Results On-Chain File: script/StoreInteraction.s.sol // SPDX-License-Identifier: MIT pragma solidity ^0.8.30; import "forge-std/Script.sol"; interface IHonkVerifierWithRecord { function verifyAndStore(bytes calldata proof, bytes32[] calldata publicInputs) external returns (bool); } contract StoreInteraction is Script { function run() external { uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); vm.startBroadcast(deployerPrivateKey); address verifierAddress = 0xNEW_ADDRESS; bytes memory proof = vm.readFileBinary("../circuits/target/proof"); bytes32[2] memory publicInputs; publicInputs[0] = bytes32(uint256(3)); publicInputs[1] = bytes32(uint256(6)); bool result = IHonkVerifierWithRecord(verifierAddress).verifyAndStore(proof, publicInputs); console.log("On-chain verification result:", result); vm.stopBroadcast(); } } 🔁 Replace: 0xNEW_ADDRESS → with the address obtained when deploying HonkVerifierWithRecord. 🧾 7. Execute On-Chain Write source .env forge script script/StoreInteraction.s.sol:StoreInteraction --rpc-url https://eth-sepolia.g.alchemy.com/v2/
<your_key> --private-key <your_private_key> --broadcast -vvvv What Happens: Foundry compiles and submits an on-chain transaction verifyAndStore() updates: lastVerification lastPublicInputs Emits ProofVerified(result) event Logs show verifyAndStore returned: true 🔍 8. View Results on Etherscan After the transaction is mined: lastVerification = true Event: ProofVerified(true) 👉 View directly on Sepolia Etherscan 🧩 9. Summary Deploying a Noir ZK verifier is only the first step Foundry automates both read and write interactions Use verify() for local verification (no gas) Use verifyAndStore() for on-chain recordkeeping Inspect contract state and logs directly on Etherscan 📚 References Noir ZK Language Foundry Documentation Ethereum Sepolia Testnet zkSNARKs Overview (ZoKrates) 👨🏽‍🏫 Contact & Credits Instructor: Dr. Cyprian Omukhwaya Sakwa Cryptography Instructor, Web3Clubs Foundation 📧 Email: cypriansakwa@gmail.com
 🐦 Twitter: @cypriansakwaOm 💻 GitHub: cypriansakwa ⚠️ Use only testnet keys and funds for all lessons.
