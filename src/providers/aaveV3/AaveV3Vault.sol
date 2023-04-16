// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { IERC20, ERC20 } from "../../periphery/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { IPool } from "./external/IPool.sol";
import { IRewardsController } from "./external/IRewardsController.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";
import "../../periphery/ERC4626Compoundable.sol";

contract AaveV3Vault is ERC4626Compoundable, WithFees {
  /// -----------------------------------------------------------------------
  /// Libraries usage
  /// -----------------------------------------------------------------------

  using SafeTransferLib for ERC20;

  /// -----------------------------------------------------------------------
  /// Constants
  /// -----------------------------------------------------------------------

  uint256 internal constant DECIMALS_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF;
  uint256 internal constant ACTIVE_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
  uint256 internal constant FROZEN_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;
  uint256 internal constant PAUSED_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF;
  uint256 internal constant SUPPLY_CAP_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;

  /// -----------------------------------------------------------------------
  /// Immutable params
  /// -----------------------------------------------------------------------

  /// @notice The Aave aToken contract
  IERC20 public immutable aToken;

  /// @notice The Aave Pool contract
  IPool public immutable lendingPool;

  /// @notice The Aave RewardsController contract
  IRewardsController public immutable rewardsController;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    IERC20 asset_,
    IERC20 aToken_,
    IPool lendingPool_,
    IRewardsController rewardsController_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  ) ERC4626Compoundable(asset_, swapper_, owner_) WithFees(feesController_) {
    aToken = aToken_;
    lendingPool = lendingPool_;
    rewardsController = rewardsController_;

    // Approve to lending pool all tokens
    aToken.approve(address(lendingPool), type(uint256).max);
    _asset.approve(address(lendingPool), type(uint256).max);
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function _totalAssets() internal view virtual override returns (uint256) {
    // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
    return aToken.balanceOf(address(this));
  }

  function beforeWithdraw(uint256 assets, uint256 /*shares*/ )
    internal
    virtual
    override
    returns (uint256)
  {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Aave
    /// -----------------------------------------------------------------------
    return lendingPool.withdraw(asset(), assets, address(this));
  }

  function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Aave
    /// -----------------------------------------------------------------------
    lendingPool.supply(asset(), assets, address(this), 0);
  }

  function maxDeposit(address owner) public view virtual override returns (uint256) {
    if (totalAssets() >= depositLimit) {
      return 0;
    }
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(asset()).configuration.data;

    if (!(_getActive(configData) && !_getFrozen(configData) && !_getPaused(configData))) {
      return 0;
    }

    // handle supply cap
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return depositLimit - totalAssets();
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap =
      supplyCapInWholeTokens * 10 ** tokenDecimals - aToken.totalSupply();
    uint256 limitCap = depositLimit - totalAssets();

    return limitCap < supplyCap ? limitCap : supplyCap;
  }

  function maxMint(address owner) public view virtual override returns (uint256) {
    if (totalAssets() >= depositLimit) {
      return 0;
    }
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(asset()).configuration.data;
    if (!(_getActive(configData) && !_getFrozen(configData) && !_getPaused(configData))) {
      return 0;
    }

    // handle supply cap
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return convertToShares(depositLimit - totalAssets());
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap =
      supplyCapInWholeTokens * 10 ** tokenDecimals - aToken.totalSupply();
    uint256 limitCap = depositLimit - totalAssets();

    return convertToShares(limitCap < supplyCap ? limitCap : supplyCap);
  }

  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(asset()).configuration.data;
    if (!(_getActive(configData) && !_getPaused(configData))) {
      return 0;
    }

    uint256 cash = _asset.balanceOf(address(aToken));
    uint256 assetsBalance = convertToAssets(balanceOf(owner));
    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(asset()).configuration.data;
    if (!(_getActive(configData) && !_getPaused(configData))) {
      return 0;
    }

    uint256 cash = _asset.balanceOf(address(aToken));
    uint256 cashInShares = convertToShares(cash);
    uint256 shareBalance = balanceOf(owner);
    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_)
    internal
    view
    override
    returns (string memory vaultName)
  {
    vaultName = string.concat("Yasp Aave v3 Vault", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_)
    internal
    view
    override
    returns (string memory vaultSymbol)
  {
    vaultSymbol = string.concat("yav3", asset_.symbol());
  }

  /// -----------------------------------------------------------------------
  /// Internal Aave functions for configData
  /// -----------------------------------------------------------------------

  function _getDecimals(uint256 configData) internal pure returns (uint8) {
    return uint8((configData & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION);
  }

  function _getActive(uint256 configData) internal pure returns (bool) {
    return configData & ~ACTIVE_MASK != 0;
  }

  function _getFrozen(uint256 configData) internal pure returns (bool) {
    return configData & ~FROZEN_MASK != 0;
  }

  function _getPaused(uint256 configData) internal pure returns (bool) {
    return configData & ~PAUSED_MASK != 0;
  }

  function _getSupplyCap(uint256 configData) internal pure returns (uint256) {
    return (configData & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  function _harvest(IERC20 reward)
    internal
    virtual
    override
    returns (uint256 rewardAmount)
  {
    address[] memory assets = new address[](1);
    assets[0] = asset();

    (, uint256[] memory claimedAmounts) =
      rewardsController.claimAllRewards(assets, address(this));
    return claimedAmounts[0];
  }

  function _tend()
    internal
    virtual
    override
    returns (uint256 wantAmount, uint256 sharesAdded)
  {
    wantAmount = _asset.balanceOf(address(this));
    sharesAdded = convertToShares(wantAmount);
    lendingPool.supply(asset(), wantAmount, address(this), 0);
  }
}
