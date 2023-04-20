// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

abstract contract ERC4626Controllable is ERC4626, Owned {
  /// @notice Maximum deposit limit
  uint256 public depositLimit;
  /// @notice Deposit status, used on emergency situation
  bool public canDeposit;
  /// @notice Admin address, preferably factory contract or multisig
  address public admin;

  /// @notice Used in reentrancy check.
  uint256 private locked = 1;
  /// @notice cached total amount.
  uint256 internal storedTotalAssets;
  /// @notice the maximum length of a rewards cycle
  uint256 public lockPeriod = 7 hours;
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

  constructor(IERC20 asset_, string memory _name, string memory _symbol, address admin_)
    ERC4626(ERC20(address(asset_)), _name, _symbol)
    Owned(admin_)
  {
    depositLimit = 1e27;
    canDeposit = true;

    unlockAt = (block.timestamp / lockPeriod) * lockPeriod;
  }

  /////// Vault settings
  function setDepositLimit(uint256 depositLimit_) public onlyOwner {
    require(depositLimit_ >= totalAssets());
    depositLimit = depositLimit_;

    emit DepositLimitUpdated(depositLimit);
  }

  ///@dev very risky method, gives owner ability to transfer funds from vault
  // function setAllowance(IERC20 asset_, address receiver, uint256 approvedAmount)
  //   public
  //   onlyOwner
  // {
  //   asset_.approve(receiver, approvedAmount);
  // }

  function setMetadata(string memory name_, string memory symbol_) public onlyOwner {
    name = name_;
    symbol = symbol_;

    emit MetadataUpdated(name_, symbol_);
  }

  function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
    lockPeriod = _lockPeriod;

    emit LockPeriodUpdated(lockPeriod);
  }

  function toggle() public onlyOwner {
    canDeposit = !canDeposit;

    emit DepositUpdated(canDeposit);
  }

  function sweep(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(asset), "Cannot withdraw the underlying token");
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

    emit Recovered(tokenAddress, tokenAmount);
  }

  function refundETH(address payable receiver, uint256 amount) external payable onlyOwner {
    (bool s,) = receiver.call{ value: amount }("");
    require(s, "ETH transfer failed");

    emit Recovered(address(0), amount);
  }

  /////////////////

  function totalAssets() public view override returns (uint256) {
    if (block.timestamp >= unlockAt) {
      return storedTotalAssets + lastUnlockedAssets;
    }

    ///@dev this is impossible, but in test environment everything is possible
    if (block.timestamp < unlockAt) {
      return storedTotalAssets;
    }

    uint256 unlockedAssets =
      (lastUnlockedAssets * (block.timestamp - lastSync)) / (unlockAt - lastSync);
    return storedTotalAssets + unlockedAssets;
  }

  function totalLiquidity() public view returns (uint256) {
    return _totalAssets();
  }

  function pnl(address user) public view returns (int256) {
    uint256 totalDeposited = depositOf[user];
    uint256 totalWithdraw = withdrawOf[user] + this.maxWithdraw(user);

    return int256(totalWithdraw) - int256(totalDeposited);
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

  function beforeWithdraw(uint256 amount, uint256 shares)
    internal
    virtual
    override
    nonReentrant
  {
    super.beforeWithdraw(amount, shares);

    storedTotalAssets -= amount;
    withdrawOf[msg.sender] += amount;
  }

  function afterDeposit(uint256 amount, uint256 shares)
    internal
    virtual
    override
    nonReentrant
  {
    require(canDeposit, "Error: Vault is withdraw-only");
    storedTotalAssets += amount;
    depositOf[msg.sender] += amount;

    super.afterDeposit(amount, shares);
  }
}
