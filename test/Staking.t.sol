// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ERC20Mint} from "../src/ERC20Mint.sol";
import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {WormholeRelayerTest} from "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

contract StakingTest is Test {
    Staking staking;
    ERC20Mint stakingToken;
    ERC20Mint rewardToken;
    address notOwner = makeAddr("notOwner");
    address user = makeAddr("user");

    function setUp() public {
        stakingToken = new ERC20Mint("staking", "ST");
        rewardToken = new ERC20Mint("reward", "RT");

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
        vm.startPrank(user);
        vm.expectRevert();
        staking.stake(0);

        uint256 amount = 250 * 10 ** 18;
        stakingToken.mint(amount);
        stakingToken.approve(address(staking), amount);
        staking.stake(amount);

        assertEq(stakingToken.balanceOf(address(staking)), amount);
        assertEq(staking.s_balanceOf(user), amount);
        assertEq(staking.s_balanceOf(address(staking)), 0);

        ///@notice withdraw 0 not allowed
        vm.expectRevert();
        staking.withdraw(0);


        stakingToken.mint(1);
        stakingToken.transfer(address(staking), 1);
        ///@notice withdraw over balance not allowed
        vm.expectRevert();
        staking.withdraw(amount + 1);

        staking.withdraw(amount / 5);

        assertEq(stakingToken.balanceOf(user), amount / 5);
        assertEq(staking.s_balanceOf(user), 4 * amount / 5);
        assertEq(staking.s_balanceOf(address(staking)), 0);

        staking.withdraw(4 * amount / 5);

        assertEq(stakingToken.balanceOf(user), amount);
        assertEq(staking.s_balanceOf(user), 0);
        assertEq(staking.s_balanceOf(address(staking)), 0);
    }
}
