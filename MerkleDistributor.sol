// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMerkleDistributor} from "./interfaces/IMerkleDistributor.sol";

error AlreadyClaimed();
error InvalidProof();

contract MerkleDistributor is IMerkleDistributor, Ownable {
    using SafeERC20 for IERC20;

    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable sweepUnclaimedTimestamp;
    uint256 public immutable burnUnclaimedTimestamp;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
        sweepUnclaimedTimestamp = block.timestamp + 3 * 30 days; // Roughly 3 months
        burnUnclaimedTimestamp = block.timestamp + 6 * 30 days; // Roughly 6 months
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external virtual override {
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node))
            revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount);
    }

    function sweepUnclaimed(address target) external onlyOwner {
        require(
            block.timestamp >= sweepUnclaimedTimestamp,
            "Too early to sweep"
        );
        require(block.timestamp < burnUnclaimedTimestamp, "Too late to sweep");

        uint256 unclaimed = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(target, unclaimed);
    }

    function burnUnclaimed() external {
        require(block.timestamp >= burnUnclaimedTimestamp, "Too early to burn");

        uint256 unclaimed = IERC20(token).balanceOf(address(this));
        IERC20(token).burn(unclaimed);
    }

    function revokeOwnership() external onlyOwner {
        renounceOwnership();
    }

    function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }
}
