pragma solidity ^0.8.4;

import { ERC20, IERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock } from "../../mocks/ERC20.m.sol";
import { ICurveGauge } from "../../../src/providers/curve/external/ICurveGauge.sol";

contract CurveGaugeMock is ICurveGauge {
  IERC20 public reward;
  IERC20 public lpToken;

  constructor(IERC20 reward_, IERC20 lpToken_) {
    reward = reward_;
    lpToken = lpToken_;
  }

  function deposit(uint256) external override { }

  function balanceOf(address) external view override returns (uint256) {
    return 0;
  }

  function claim_rewards() external override { }

  function claimable_tokens(address) external view override returns (uint256) {
    return 0;
  }

  function claimable_reward(address _addressToCheck, address _rewardToken)
    external
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function withdraw(uint256) external override { }

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
