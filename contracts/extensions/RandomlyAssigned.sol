// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './WithLimitedSupplyAndReserves.sol';

/// @author 1001.digital | edit: Eman Herawy
/// @title Randomly assign tokenIDs from a given set of tokens.
abstract contract RandomlyAssigned is WithLimitedSupplyAndReserves {
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The initial token ID
    uint256 private startFrom;

    /// Instanciate the contract
    /// @param _startFrom the tokenID with which to start counting
    function _randomlyAssigned_init(uint256 _startFrom) internal {
        startFrom = _startFrom;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken() internal override ensureAvailability returns (uint256) {
        uint256 maxIndex = maxSupply() - tokenCount();
        uint256 random = uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, block.difficulty, block.gaslimit, block.timestamp))
        ) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        super.nextToken();

        return value + startFrom;
    }
}
