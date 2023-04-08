// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStargateLPStaking } from
  "../../../src/providers/stargate/external/IStargateLPStaking.sol";
import { ERC20Mock } from "../../mocks/ERC20.m.sol";
import { StakePoolMock } from "../../mocks/StakePool.m.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract StargateLPStakingMock is IStargateLPStaking, StakePoolMock {
  ERC20Mock public lpToken;
  ERC20Mock public reward;
  UserInfo userInfo_;
  PoolInfo poolInfo_;

  constructor(ERC20Mock lpToken_, ERC20Mock reward_) StakePoolMock(lpToken_, reward_) {
    lpToken = lpToken_;
    reward = reward_;
  }

  function userInfo(uint256 _pid, address _owner) external view returns (UserInfo memory) {
    return UserInfo({
      amount: balanceOf(_owner),
      rewardDebt: userRewardPerTokenPaid[_owner]
    });
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
    return PoolInfo({
      lpToken: IERC20(address(lpToken)),
      allocPoint: 4000,
      lastRewardBlock: lastUpdateTime,
      accStargatePerShare: rewardPerTokenStored
    });
  }

  function deposit(uint256 _pid, uint256 _amount) external {
    depositStake(_amount);
    collectRewardTokens();
  }

  function withdraw(uint256 _pid, uint256 _amount) external {
    withdrawStake(_amount);
    collectRewardTokens();
  }

  function pendingStargate(uint256 _pid, address _user) public view returns (uint256) {
    return pendingReward(_user);
  }
}
