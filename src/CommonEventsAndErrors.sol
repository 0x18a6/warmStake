// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library CommonEventsAndErrors {
    event RewardDurationSet(uint256 duration);
    event RewardAmountNotified(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error InvalidParam();
    error InvalidOperation();
}
