// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./ERC4626Controllable.sol";
import { IERC4626 } from "./ERC4626.sol";
import "./Swapper.sol";

interface IERC4626Compoundable {
  function setSwapper(ISwapper nextSwapper) external;
  function expectedReturns(uint256 timestamp) external view returns (uint256);

  function harvest(IERC20 reward, uint256 swapAmountOut)
    external
    returns (uint256, uint256);
  function tend() external returns (uint256, uint256);
}

abstract contract ERC4626Compoundable is IERC4626Compoundable, ERC4626Controllable {
  /// @notice Swapper contract
  ISwapper public swapper;
  /// @notice total earned amount, used only for expectedReturns()
  uint256 public totalEarned;
  /// @notice timestamp of last tend() call
  uint256 public lastTend;
  /// @notice creation timestamp.
  uint256 public created;

  bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

  event Harvest(uint256 amountReward, uint256 amountWant);
  event Tend(uint256 amountWant, uint256 feesAmount);
  event SwapperUpdated(address newSwapper);

  constructor(IERC20 asset_, ISwapper swapper_, address admin_)
    ERC4626Controllable(asset_, admin_)
  {
    swapper = swapper_;
    lastTend = block.timestamp;
    created = block.timestamp;
  }

  function setKeeper(address account, bool remove) public onlyRole(MANAGEMENT_ROLE) {
    setRole(KEEPER_ROLE, account, remove);
  }

  function setSwapper(ISwapper nextSwapper) public onlyRole(MANAGEMENT_ROLE) {
    swapper = nextSwapper;

    emit SwapperUpdated(address(swapper));
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= unlockAt, "Unexpected timestamp");

    if (lastTend > created) {
      return totalEarned * (timestamp - lastTend) / (lastTend - created);
    } else {
      return 0;
    }
  }

  function harvest(IERC20 reward, uint256 swapAmountOut)
    public
    onlyRole(KEEPER_ROLE)
    returns (uint256 rewardAmount, uint256 wantAmount)
  {
    rewardAmount = _harvest(reward);

    if (rewardAmount > 0) {
      wantAmount = swapper.swap(reward, _asset, rewardAmount, swapAmountOut);
    } else {
      wantAmount = 0;
    }

    emit Harvest(rewardAmount, wantAmount);
  }

  function tend()
    public
    onlyRole(KEEPER_ROLE)
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    (wantAmount, feesAmount) = _tend();

    totalEarned += wantAmount;
    lastTend = block.timestamp;

    emit Tend(wantAmount, feesAmount);
  }

  function _harvest(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function _tend() internal virtual returns (uint256 wantAmount, uint256 feesAmount);
}
