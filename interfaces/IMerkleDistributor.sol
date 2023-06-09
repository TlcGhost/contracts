// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns the timestamp after which unclaimed tokens can be swept.
    function sweepUnclaimedTimestamp() external view returns (uint256);

    // Returns the timestamp after which unclaimed tokens can be burned.
    function burnUnclaimedTimestamp() external view returns (uint256);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // Sweeps unclaimed tokens to the given address. Callable by owner only, >3 months and <6 months post deploy.
    function sweepUnclaimed(address target) external;

    // Burns unclaimed tokens. Callable by anyone, >6 months post deploy.
    function burnUnclaimed() external; // New

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}
