// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract VestingExt {
  /// @notice the maximum length of a rewards cycle
  uint256 public lockPeriod = 7 hours;
  /// @notice the amount of rewards distributed in a the most recent cycle.
  uint256 public lastGainedAssets;
  /// @notice the effective start of the current cycle
  uint256 public lastSync;
  /// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
  uint256 public unlockAt;

  /// @notice cached total amount.
  uint256 internal storedTotalAssets;

  event Sync(uint256 unlockAt, uint256 amountWant);

  constructor() {
    unlockAt = (block.timestamp / lockPeriod) * lockPeriod;
  }

  function sync() public {
    require(block.timestamp >= unlockAt, "Error: rewards is still locked");

    uint256 lastTotalAssets = storedTotalAssets + lastGainedAssets;
    uint256 totalAssets_ = Vesting_totalLiquidity();

    require(totalAssets_ >= lastTotalAssets, "Error: vault have lose");

    uint256 nextGainedAssets = totalAssets_ - lastTotalAssets;
    uint256 end = ((block.timestamp + lockPeriod) / lockPeriod) * lockPeriod;

    storedTotalAssets += lastGainedAssets;
    lastGainedAssets = nextGainedAssets;
    lastSync = block.timestamp;
    unlockAt = end;

    emit Sync(end, nextGainedAssets);
  }

  function Vesting_totalAssets() internal view returns (uint256 assets) {
    if (block.timestamp >= unlockAt) {
      return storedTotalAssets + lastGainedAssets;
    }

    ///@dev this is impossible, but in test environment everything is possible
    if (block.timestamp < unlockAt) {
      return storedTotalAssets;
    }

    uint256 gainedAssets =
      (lastGainedAssets * (block.timestamp - lastSync)) / (unlockAt - lastSync);
    return storedTotalAssets + gainedAssets;
  }

  function Vesting_increaseStoredAssets(uint256 gainAmount) internal {
    storedTotalAssets += gainAmount;
  }

  function Vesting_decreaseStoredAssets(uint256 lossAmount) internal {
    require(storedTotalAssets >= lossAmount, "Error: storedAssets < lossAmount");

    storedTotalAssets -= lossAmount;
  }

  ///@dev Vesting_totalLiquidity() returns total assets that in vault's control
  function Vesting_totalLiquidity() internal view virtual returns (uint256 assets);
}
