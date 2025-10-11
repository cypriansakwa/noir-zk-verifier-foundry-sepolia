// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Verifier.sol"; // uses your existing Verifier.sol which defines HonkVerifier

/// @title HonkVerifierWithRecord
/// @notice Extends HonkVerifier to persist the latest verification result on-chain
contract HonkVerifierWithRecord is HonkVerifier {
    bool public lastVerification;            // Stores last verification result
    bytes32[] public lastPublicInputs;       // Stores last public inputs (for audit)
    event ProofVerified(bool result);        // Emitted when verifyAndStore runs

    /// @notice Verifies proof and stores the result on-chain
    /// @param proof The proof bytes
    /// @param publicInputs The array of public inputs
    /// @return result Boolean result of verification
    function verifyAndStore(bytes calldata proof, bytes32[] calldata publicInputs)
        external
        returns (bool result)
    {
        // Call existing verify() from parent HonkVerifier
        result = verify(proof, publicInputs);

        // Store result
        lastVerification = result;

        // Replace stored public inputs with the new ones
        delete lastPublicInputs;
        for (uint256 i = 0; i < publicInputs.length; i++) {
            lastPublicInputs.push(publicInputs[i]);
        }

        // Emit an event so you can watch logs on Etherscan / off-chain
        emit ProofVerified(result);
    }
}
