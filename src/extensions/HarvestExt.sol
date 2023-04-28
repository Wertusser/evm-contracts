// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import { ISwapper } from "../periphery/Swapper.sol";

abstract contract HarvestExt {
  /// @notice Swapper contract
  ISwapper public swapper;
  /// @notice total earned amount, used only for expectedReturns()
  uint256 public totalGain;
  /// @notice timestamp of last tend() call
  uint256 public lastTend;
  /// @notice creation timestamp.
  uint256 public created;

  event Harvest(uint256 amountReward);
  event Tend(uint256 amountWant, uint256 feesAmount);

  constructor(ISwapper swapper_) {
    swapper = swapper_;
    lastTend = block.timestamp;
    created = block.timestamp;
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= lastTend, "Unexpected timestamp");

    if (lastTend > created) {
      return totalGain * (timestamp - lastTend) / (lastTend - created);
    } else {
      return 0;
    }
  }

  function Harvest_collectRewards(IERC20 reward)
    internal
    virtual
    returns (uint256 rewardAmount)
  {
    _collectRewards(reward);

    rewardAmount = reward.balanceOf(address(this));

    emit Harvest(rewardAmount);
  }

  function Harvest_swap(IERC20 from, IERC20 to, uint256 amountIn, uint256 minAmountOut)
    internal
    virtual
    returns (uint256 amountOut)
  {
    amountOut = swapper.swap(from, to, amountIn, minAmountOut);
  }

  function Harvest_tend()
    internal
    virtual
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    (wantAmount, feesAmount) = _reinvest();

    totalGain += wantAmount;
    lastTend = block.timestamp;

    emit Tend(wantAmount, feesAmount);
  }

  function _collectRewards(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function _reinvest() internal virtual returns (uint256 wantAmount, uint256 feesAmount);
}
