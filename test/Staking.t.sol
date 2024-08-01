// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {WormholeRelayerTest} from "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

contract StakingTest is Test {
    Staking staking;
    IERC20 stakingToken;
    IERC20 rewardToken;
    address notOwner = makeAddr("notOwner");
    address user = makeAddr("user");

    function setUp() public {
        staking = new Staking(address(stakingToken), address(rewardToken));
    }

    function test_setWithdrawDuration() external {
        ///@notice _duration > MIN_REWARD_DURAION
        staking.setRewardsDuration(8 days);

        ///@notice _duration < MIN_REWARD_DURAION
        vm.expectRevert();
        staking.setRewardsDuration(6 days);

        ///@notice notOwner can't set the withdraw duration
        vm.expectRevert();
        vm.prank(notOwner);
        staking.setRewardsDuration(8 days);
    }

    function test_stake() external {
        ///@notice stake 0 not allowed
        vm.prank(user);
        vm.expectRevert();
        staking.stake(0);
    }
}
