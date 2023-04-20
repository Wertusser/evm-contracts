// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import "./Swapper.sol";

abstract contract ERC4626Controllable is ERC4626, Owned {
  uint256 public depositLimit;
  bool public canDeposit;
  address public admin;

  /// @notice Used in reentrancy check.
  uint256 private locked = 1;

  /// @notice cached total amount.
  uint256 internal storedTotalAssets;
  /// @notice the maximum length of a rewards cycle
  uint256 public lockPeriod = 3;
  /// @notice the amount of rewards distributed in a the most recent cycle.
  uint256 public lastUnlockedAssets;
  /// @notice the effective start of the current cycle
  uint256 public lastSync;
  /// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
  uint256 public unlockAt;

  mapping(address => uint256) public depositOf;
  mapping(address => uint256) public withdrawOf;

  event DepositUpdated(bool canDeposit);
  event DepositLimitUpdated(uint256 depositLimit);
  event MetadataUpdated(string name, string symbol);
  event LockPeriodUpdated(uint256 newLockPeriod);

  event Recovered(address token, uint256 amount);
  event Sync(uint256 unlockAt, uint256 amountWant);

  modifier nonReentrant() {
    require(locked == 1, "Non-reentrancy guard");
    locked = 2;
    _;
    locked = 1;
  }

  constructor(IERC20 asset_, address admin_) ERC4626(asset_) Owned(admin_) {
    depositLimit = type(uint256).max;
    // depositLimit = 1e18;
    canDeposit = true;

    unlockAt = (block.timestamp / lockPeriod) * lockPeriod;
  }

  /////// Vault settings

  function toggle() public onlyOwner {
    canDeposit = !canDeposit;

    emit DepositUpdated(canDeposit);
  }

  function setDepositLimit(uint256 depositLimit_) public onlyOwner {
    require(depositLimit_ >= totalAssets());
    depositLimit = depositLimit_;

    emit DepositLimitUpdated(depositLimit);
  }

  function setMetadata(string memory name_, string memory symbol_) public onlyOwner {
    name = name_;
    symbol = symbol_;

    emit MetadataUpdated(name_, symbol_);
  }

  function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
    lockPeriod = _lockPeriod;

    emit LockPeriodUpdated(lockPeriod);
  }

  /////////////////

  function totalAssets() public view override returns (uint256) {
    if (block.timestamp >= unlockAt) {
      return storedTotalAssets + lastUnlockedAssets;
    }

    uint256 unlockedAssets =
      (lastUnlockedAssets * (block.timestamp - lastSync)) / (unlockAt - lastSync);
    return storedTotalAssets + unlockedAssets;
  }

  function pnl(address user) public view returns (int256) {
    uint256 totalDeposited = depositOf[user];
    uint256 totalWithdraw = withdrawOf[user] + this.maxWithdraw(user);

    return int256(totalWithdraw) - int256(totalDeposited);
  }

  ////////////////

  function sweep(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(asset()), "Cannot withdraw the underlying token");
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

    emit Recovered(tokenAddress, tokenAmount);
  }

  function refundETH(address payable receiver, uint256 amount) external payable onlyOwner {
    (bool s,) = receiver.call{ value: amount }("");
    require(s, "ETH transfer failed");

    emit Recovered(address(0), amount);
  }

  function sync() public virtual {
    require(block.timestamp >= unlockAt, "Error: rewards is still locked");

    uint256 lastTotalAssets = storedTotalAssets + lastUnlockedAssets;
    uint256 totalAssets_ = _totalAssets();
    
    require(totalAssets_ >= lastTotalAssets, "Error: vault have lose");

    uint256 nextUnlockedAssets = totalAssets_ - lastTotalAssets;
    uint256 end = ((block.timestamp + lockPeriod) / lockPeriod) * lockPeriod;

    storedTotalAssets += lastUnlockedAssets;
    lastUnlockedAssets = nextUnlockedAssets;
    lastSync = block.timestamp;
    unlockAt = end;

    emit Sync(end, nextUnlockedAssets);
  }

  ////////////////

  function _totalAssets() internal view virtual returns (uint256 assets);
  /**
   * @dev Deposit/mint common workflow.
   */

  function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    virtual
    override
  {
    require(canDeposit, "Error: deposits is currently paused");
    require(totalAssets() + assets <= depositLimit, "Error: deposit overflow");

    IERC20(asset()).transferFrom(caller, address(this), assets);
    _mint(receiver, shares);

    depositOf[receiver] += assets;
    storedTotalAssets += assets;

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Withdraw/redeem common workflow.
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }

    _burn(owner, shares);
    IERC20(asset()).transfer(receiver, assets);

    withdrawOf[receiver] += assets;
    storedTotalAssets -= assets;

    emit Withdraw(caller, receiver, owner, assets, shares);
  }
}
