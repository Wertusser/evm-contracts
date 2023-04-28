// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ERC4626Owned } from "./ERC4626Owned.sol";
import { VestingExt } from "../extensions/VestingExt.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

abstract contract ERC4626Vesting is ERC4626Owned, VestingExt {
  event LockPeriodUpdated(uint256 newLockPeriod);

  constructor(IERC20 asset_, string memory _name, string memory _symbol, address admin_)
    ERC4626Owned(asset_, _name, _symbol, admin_)
  { }

  function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
    lockPeriod = _lockPeriod;

    emit LockPeriodUpdated(lockPeriod);
  }

  /////////////////

  function totalAssets() public view override returns (uint256) {
    return Vesting_totalAssets();
  }

  function Vesting_totalLiquidity()
    internal
    view
    virtual
    override
    returns (uint256 assets)
  {
    return _totalFunds();
  }

  function beforeWithdraw(uint256 amount, uint256 shares)
    internal
    virtual
    override
    returns (uint256 assets)
  {
    assets = super.beforeWithdraw(amount, shares);

    Vesting_decreaseStoredAssets(assets);
  }

  function afterDeposit(uint256 amount, uint256 shares) internal virtual override {
    Vesting_increaseStoredAssets(amount);

    super.afterDeposit(amount, shares);
  }

  ////////////////

  function _totalFunds() internal view virtual returns (uint256 assets);
}
