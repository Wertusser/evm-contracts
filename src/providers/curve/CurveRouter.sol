// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/Router.sol";

import { ICurvePool } from "./external/ICurvePool.sol";
import { ICurveGauge, ICurveMinter } from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveRouter is Router {
  struct CurveContext {
    address pool;
    address gauge;
  }

  constructor(IWETH weth) Router(weth) {

  }

  function addLiquidity(uint256[] memory assets, CurveContext memory context) public { }
  function removeLiquidity(uint256 lpAmount, CurveContext memory context) public { }

  function withdrawStake(uint256 lpAmount, CurveContext memory context) public { }

  function depositStake(uint256 lpAmount, CurveContext memory context) public { }

  function harvest(IERC20 reward, CurveContext memory context)
    internal
    returns (uint256 rewardAmount)
  {
    // require(curveGauge.claimable_tokens(address(this)) > 0, "Error: zero rewards to claim");
    uint256 rewardBefore = reward.balanceOf(address(this));
    ICurveGauge(context.gauge).claim_rewards();
    uint256 rewardAfter = reward.balanceOf(address(this));
    rewardAmount = rewardAfter - rewardBefore;
  }
}
