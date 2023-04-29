// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import { ISwapper } from "../periphery/Swapper.sol";

abstract contract HarvestExt {
  address public keeper;
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

  constructor(address keeper_, ISwapper swapper_) {
    keeper = keeper_;
    swapper = swapper_;
    lastTend = block.timestamp;
    created = block.timestamp;
  }

  modifier onlyKeeper() {
    require(msg.sender == keeper, "Error: keeper only method");
    _;
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= lastTend, "Unexpected timestamp");

    if (lastTend > created) {
      return totalGain * (timestamp - lastTend) / (lastTend - created);
    } else {
      return 0;
    }
  }

  function harvest(IERC20 reward)
    public
    virtual
    onlyKeeper
    returns (uint256 rewardAmount)
  {
    Harvest__collectRewards(reward);

    rewardAmount = reward.balanceOf(address(this));

    emit Harvest(rewardAmount);
  }

  function swap(IERC20 fromAsset, IERC20 toAsset, uint256 amountIn, uint256 minAmountOut)
    public
    virtual
    onlyKeeper
    returns (uint256 amountOut)
  {
    fromAsset.approve(address(swapper), amountIn);
    amountOut = swapper.swap(fromAsset, toAsset, amountIn, minAmountOut);
  }

  function tend()
    public
    virtual
    onlyKeeper
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    (wantAmount, feesAmount) = Harvest__reinvest();

    totalGain += wantAmount;
    lastTend = block.timestamp;

    emit Tend(wantAmount, feesAmount);
  }


  function Harvest__collectRewards(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function Harvest__reinvest() internal virtual returns (uint256 wantAmount, uint256 feesAmount);
}
