# 🧮 Noir Modular Exponentiation — ZK Proof + Foundry Deployment on Sepolia

This project demonstrates a **Zero-Knowledge Proof (ZKP)** circuit using **Noir** to prove knowledge of a modular exponentiation computation without revealing the base or exponent.  
You’ll also learn how to **deploy and verify** the generated **Solidity verifier** on the **Sepolia testnet** using Foundry.

---

## 🚀 Overview

In this tutorial, you’ll:

1. Implement a modular exponentiation circuit in Noir.  
2. Generate a proof using the `bb` or `bb.js` backend.  
3. Integrate the generated Solidity verifier into a Foundry project.  
4. Deploy and verify the verifier contract on **Sepolia Etherscan**.  
5. Interact with your deployed contract and verify proofs on-chain.

---

## 🧩 Circuit Description

The circuit computes:

$\text{result} \;=\; \text{rbase}^\text{rexponent}\; \mod \;\text{rmodulus}$

```swift
The goal is to prove that you know `x` and `e` such that:
```
$y = x^e \mod m$

```rust

### 🧠 Circuit Code (`src/main.nr`)

```rust
/// Modular exponentiation using branchless right-to-left binary method.
/// Returns (base^exponent) mod modulus as a Field element.
/// All inputs are u32, output is Field.
fn mod_exp_branchless_u32(mut base: u32, mut exponent: u32, modulus: u32) -> u32 {
    assert(modulus != 0, "Modulus must be nonzero");
    let mut result: u32 = 1;
    base = base % modulus;

    for _ in 0..32 {
        let bit = exponent & 1;
        let mult = (result * base) % modulus;
        result = mult * bit + result * (1 - bit);
        base = (base * base) % modulus;
        exponent = exponent >> 1;
    }
    result
}

/// Main entry point for the circuit.
/// All inputs are u32, output is public Field.
fn main(x: u32, e: u32, m: u32, y: pub Field) {
    assert(m != 0, "Modulus must be nonzero");
    let result: u32 = mod_exp_branchless_u32(x, e, m);
    assert(result.into() == y);
}
```
```markdown
## 🧾 Inputs

| Parameter | Visibility | Description |
|------------|-------------|-------------|
| `x` | private | base |
| `e` | private | exponent |
| `m` | private | modulus |
| `y` | public | result (`x^e mod m`) |

---

## 🗂 Project Structure

| Folder | Description |
|---------|--------------|
| `/circuits` | Contains Noir source, build, and proof generation scripts |
| `/contract` | Foundry project for Solidity verifier and tests |
| `/js` | JavaScript proof generation utilities (`bb.js`) |

**Tested with:**

- **Noir ≥ 1.0.0-beta.6**  
- **bb ≥ 0.84.0**

---

## ⚙️ Installation / Setup

```bash
# Clone and initialize submodules
git submodule update --init --recursive

# Build Noir circuit and generate verifier
(cd circuits && ./build.sh)

# Install JS dependencies
(cd js && yarn)
```
## 🧾 .env Example

Create a `.env` file at your project root:
```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```
## 🧮 Proof Generation (bb.js)
```bash
# Generate proof via bb.js script
(cd js && yarn generate-proof)

# Run Foundry test to verify proof
(cd contract && forge test --optimize --optimizer-runs 5000 --gas-report -vvv)
```
**CLI Alternative (using bb directly):**
```bash
# Generate witness
nargo execute

# Generate proof with keccak oracle
bb prove \
  -b ./target/noir_modular_exponentiation.json \
  -w ./target/noir_modular_exponentiation.gz \
  -o ./target \
  --oracle_hash keccak
```
## 🧱 Deploying Verifier to Sepolia

 ### Prerequisites

 - Noir toolchain (`noirup`, `nargo`)  
 - Foundry (`forge`, `cast`)  
 - RPC endpoint (Alchemy / Infura)  
 - Etherscan API key  
 - Testnet ETH (Sepolia)  

---

 ### 1️⃣ Build the Noir circuit

 ```bash
 cd circuits
 nargo build
 ```
 **Expected output:**
```pgsql
target/
 ├─ honk-verifier-contract/Verifier.sol
 ├─ noir_modular_exponentiation.json
 ├─ noir_modular_exponentiation.gz
 ├─ public_inputs
 └─ vk/
```
 ### 2️⃣ Prepare Foundry project
 ```bash
 cd contract
 forge init
 ```
 Copy the verifier:
 ```bash
 cp ../circuits/target/honk-verifier-contract/Verifier.sol ./src/Verifier.sol
 ```
 ### 3️⃣ Deploy Script — `script/Deploy.s.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "../src/Verifier.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        HonkVerifier verifier = new HonkVerifier();
        console.log("Verifier deployed at:", address(verifier));
        vm.stopBroadcast();
    }
}
```
 ### 4️⃣ Deploy to Sepolia
 ```bash
 source .env

  forge script script/Deploy.s.sol:DeployScript \
   --rpc-url $SEPOLIA_RPC_URL \
   --private-key $PRIVATE_KEY \
   --broadcast

 ```
 **Example output:**
 ```yaml
 Verifier deployed at: 0xD7148e6Cf725290fdCAbF06519aA1C0031A562c9
 Chain: 11155111 (Sepolia)
 Gas used: 6136249
 ```
 If you want to see and intract with your deployed contract, paste the deployment address your browser as   https://sepolia.etherscan.io/address/<address> (e.g https://sepolia.etherscan.io/address/0x3e96C09d2361d27D577f18BD20Aa5A86CB313AB0)
## 🧪 VerifyProof Test Contract — `test/VerifyProof.t.sol`
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Verifier.sol";

contract VerifyProofTest is Test {
    HonkVerifier public verifier;
    bytes32[] publicInputs;

    function setUp() public {
        verifier = HonkVerifier(payable(0xD7148e6Cf725290fdCAbF06519aA1C0031A562c9));
        publicInputs.push(bytes32(uint256(2)));
    }

    function testVerifyProof() public {
        bytes memory proof = vm.readFileBinary("../circuits/target/proof");
        bool result = verifier.verify(proof, publicInputs);
        assert(result);
    }
}

```
 ### 🔍 Verify Contract on Sepolia Etherscan

  Check compiler version:
  ```bash
  jq '.compiler.version' out/Verifier.sol/HonkVerifier.json
  ```
  Then run:
  
  ```bash
   forge verify-contract \
   0xYOUR_DEPLOYED_ADDRESS \
  ./Verifier.sol:HonkVerifier \
  --chain sepolia \
  --compiler-version v0.8.30+commit.73712a01 \
  --num-of-optimizations 200 \
  --etherscan-api-key $ETHERSCAN_API_KEY
  ```
  Check status:
  ```bash
   forge verify-check \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  <your-guid>
  ```
## 💬 Interacting with Verified Contract

 ### 🧭 Steps

 1. Go to **[Sepolia Etherscan](https://sepolia.etherscan.io)**
 2. Open your **deployed contract address**
 3. Click the **Read Contract** tab
 4. Connect to **MetaMask (Sepolia network)**
 5. Call `verify(proof, publicInputs)` with your generated proof data

---

## 🧰 Proof & Input Preparation

Convert compressed proof to hex:

```bash
xxd -p noir_modular_exponentiation.gz | tr -d '\n' > proof.hex
cat proof.hex | sed 's/^/0x/' > proof.prefixed.hex

```
## 🧠 Troubleshooting

| Issue | Fix |
|-------|-----|
| **Bytecode mismatch** | Ensure same compiler version used in deploy + verify |
| **Verification failed** | Do not edit `Verifier.sol` after deployment |
| **Invalid proof format** | Use `vm.readFileBinary`, not `vm.readFile` |
| **GUID error** | Use full GUID from `verify` output |

---

## 🧩 Best Practices

- 📌 Pin compiler version in `foundry.toml`
- 🚫 Never modify verifier before verification
- 🔒 Store `.env` securely (`.gitignore` it)
- 🧾 Keep `broadcast/run-latest.json` for reference
- ⚙️ Automate with a `Makefile` or deploy script

---

## ✅ End-to-End Checklist

1. 🧱 Compile Noir circuit (`nargo build`)
2. 🔐 Generate proof (`bb prove` or `yarn generate-proof`)
3. 📋 Copy `Verifier.sol` into Foundry project
4. 🚀 Deploy using `forge script --broadcast`
5. 🔎 Verify on Etherscan
6. 🧪 Test proof verification (`forge test`)
7. ✅ Confirm success on-chain via Etherscan
