// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CommonEventsAndErrors} from "./CommonEventsAndErrors.sol";

/**
 * @title Staking
 * @notice Stakers deposit i_stakingToken and claim rewards in i_rewardToken
 */
contract Staking is Ownable(msg.sender) {
    IERC20 public immutable i_stakingToken;
    IERC20 public immutable i_rewardToken;

    uint256 constant MIN_REWARD_DURAION = 7 days;

    uint256 public s_totalSupply;
    uint256 public s_duration;
    uint256 public s_finishAt;
    uint256 public s_updatedAt;
    uint256 public s_rewardRate;
    uint256 public s_rewardPerTokenStored;

    mapping(address => uint256) public s_balanceOf;
    mapping(address user => uint256 rewards) public s_userRewardPerTokenPaid;
    mapping(address user => uint256 rewards) public s_rewardsToBeClaimed;

    event RewardDurationSet(uint256 duration);
    event RewardAmountNotified(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardToken) {
        i_stakingToken = IERC20(_stakingToken);
        i_rewardToken = IERC20(_rewardToken);
    }

    /**
     * @notice Sets the duration of the staking rewards
     * @param _duration The duration of the staking rewards
     */
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        if (_duration < MIN_REWARD_DURAION) {
            revert CommonEventsAndErrors.InvalidOperation();
        }
        if (block.timestamp < s_finishAt) {
            revert CommonEventsAndErrors.InvalidParam();
        }
        s_duration = _duration;
        emit CommonEventsAndErrors.RewardDurationSet(_duration);
    }

    /**
     * @notice Notifies the amount of the staking rewards
     * @param _amount The amount of the staking rewards
     */
    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= s_finishAt) {
            s_rewardRate = _amount / s_duration;
        } else {
            uint256 remainingRewards = (s_finishAt - block.timestamp) * s_rewardRate;
            s_rewardRate = (_amount + remainingRewards) / s_duration;
        }

        if (s_rewardRate == 0) {
            revert CommonEventsAndErrors.InvalidParam();
        }

        if (s_rewardRate * s_duration >= i_rewardToken.balanceOf(address(this))) {
            revert CommonEventsAndErrors.InvalidOperation();
        }

        s_finishAt = block.timestamp + s_duration;
        s_updatedAt = block.timestamp;
        emit CommonEventsAndErrors.RewardAmountNotified(_amount);
    }

    /**
     * @notice Allows a user to stake a certain amount of tokens
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external updateReward(msg.sender) {
        if (_amount == 0) {
            revert CommonEventsAndErrors.InvalidParam();
        }
        i_stakingToken.transferFrom(msg.sender, address(this), _amount);
        s_balanceOf[msg.sender] += _amount;
        s_totalSupply += _amount;
        emit CommonEventsAndErrors.Staked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to withdraw a certain amount of their staked tokens
     * @param _amount The amount of staked tokens to withdraw
     */
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        if (_amount == 0) {
            revert CommonEventsAndErrors.InvalidParam();
        }
        s_balanceOf[msg.sender] -= _amount;
        s_totalSupply -= _amount;
        i_stakingToken.transfer(msg.sender, _amount);
        emit CommonEventsAndErrors.Withdrawn(msg.sender, _amount);
    }

    function _rewardPerToken() internal view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }

        return
            s_rewardPerTokenStored + (s_rewardRate * (_lastTimeRewardApplicable() - s_updatedAt) * 1e18) / s_totalSupply;
    }

    function _lastTimeRewardApplicable() internal view returns (uint256) {
        return s_finishAt < block.timestamp ? s_finishAt : block.timestamp;
    }

    function _earned(address _account) public view returns (uint256) {
        return ((s_balanceOf[_account] * (_rewardPerToken() - s_userRewardPerTokenPaid[_account])) / 1e18)
            + s_rewardsToBeClaimed[_account];
    }

    modifier updateReward(address _account) {
        s_rewardPerTokenStored = _rewardPerToken();
        s_updatedAt = _lastTimeRewardApplicable();

        if (_account == address(0)) {
            revert CommonEventsAndErrors.InvalidParam();
        }

        s_rewardsToBeClaimed[_account] = _earned(_account);
        s_userRewardPerTokenPaid[_account] = s_rewardPerTokenStored;
        _;
    }
}
