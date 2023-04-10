pragma solidity ^0.8.4;

import { ERC20, IERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock } from "../../mocks/ERC20.m.sol";
import { StakePoolMock } from "../../mocks/StakePool.m.sol";
import { ICurveGauge } from "../../../src/providers/curve/external/ICurveGauge.sol";
import "forge-std/Test.sol";

contract CurveGaugeMock is ICurveGauge, StakePoolMock {
  ERC20Mock public reward;
  ERC20Mock public lpToken;

  constructor(ERC20Mock reward_, ERC20Mock lpToken_) StakePoolMock(lpToken_, reward_) {
    reward = reward_;
    lpToken = lpToken_;
    addRewardTokens(1000 * 1e18);
  }

  function claim_rewards() external override {
    collectRewardTokens();
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override(ICurveGauge, StakePoolMock)
    returns (uint256)
  {
    return _balances[owner];
  }

  function claimable_tokens(address owner) external view override returns (uint256) {
    return pendingReward(owner);
  }

  function claimable_reward(address _addressToCheck, address _rewardToken)
    external
    view
    override
    returns (uint256)
  {
    return pendingReward(_addressToCheck);
  }

  function deposit(uint256 _amount) external {
    if (_amount == 0) {
      return;
    }
    depositStake(_amount);
  }

  function withdraw(uint256 _amount) external {
    if (_amount == 0) {
      return;
    }
    withdrawStake(_amount);
  }

  function reward_tokens(uint256) external view override returns (address) {
    return address(reward);
  }

  function rewarded_token() external view override returns (address) {
    return address(reward);
  }

  function lp_token() external view override returns (address) {
    return address(lpToken);
  }
}
