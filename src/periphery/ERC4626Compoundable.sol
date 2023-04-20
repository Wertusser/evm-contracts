// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import "./ERC4626Controllable.sol";
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
  /// @notice Keeper EOA
  address public keeper;
  /// @notice Swapper contract
  ISwapper public swapper;
  /// @notice total earned amount, used only for expectedReturns()
  uint256 public totalGain;
  /// @notice timestamp of last tend() call
  uint256 public lastTend;
  /// @notice creation timestamp.
  uint256 public created;

  bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

  event Harvest(uint256 amountReward, uint256 amountWant);
  event Tend(uint256 amountWant, uint256 feesAmount);
  event SwapperUpdated(address newSwapper);
  event KeeperUpdated(address newKeeper);

  modifier onlyKeeper() {
    require(msg.sender == keeper, "Error: keeper only method");
    _;
  }

  constructor(
    IERC20 asset_,
    string memory _name,
    string memory _symbol,
    ISwapper swapper_,
    address admin_
  ) ERC4626Controllable(asset_, _name, _symbol, admin_) {
    swapper = swapper_;
    lastTend = block.timestamp;
    created = block.timestamp;
  }

  function setKeeper(address account) public onlyOwner {
    keeper = account;

    emit KeeperUpdated(account);
  }

  function setSwapper(ISwapper nextSwapper) public onlyOwner {
    swapper = nextSwapper;

    emit SwapperUpdated(address(swapper));
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= unlockAt, "Unexpected timestamp");

    if (lastTend > created) {
      return totalGain * (timestamp - lastTend) / (lastTend - created);
    } else {
      return 0;
    }
  }

  function harvest(IERC20 reward, uint256 swapAmountOut)
    public
    onlyKeeper
    returns (uint256 rewardAmount, uint256 wantAmount)
  {
    rewardAmount = _harvest(reward);

    if (rewardAmount > 0) {
      wantAmount =
        swapper.swap(reward, IERC20(address(asset)), rewardAmount, swapAmountOut);
    } else {
      wantAmount = 0;
    }

    emit Harvest(rewardAmount, wantAmount);
  }

  function tend() public onlyKeeper returns (uint256 wantAmount, uint256 feesAmount) {
    (wantAmount, feesAmount) = _tend();

    totalGain += wantAmount;
    lastTend = block.timestamp;

    emit Tend(wantAmount, feesAmount);
  }

  function harvestTend(IERC20 reward, uint256 swapAmountOut)
    public
    onlyKeeper
    returns (uint256 rewardAmount, uint256 wantAmount, uint256 feeAmount)
  {
    (rewardAmount,) = harvest(reward, swapAmountOut);
    (wantAmount, feeAmount) = tend();
  }

  function _harvest(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function _tend() internal virtual returns (uint256 wantAmount, uint256 feesAmount);
}
