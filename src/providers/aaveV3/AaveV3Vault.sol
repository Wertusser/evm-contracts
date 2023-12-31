// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { IPool } from "./external/IPool.sol";
import { IRewardsController } from "./external/IRewardsController.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";
import "../../periphery/ERC4626Owned.sol";

contract AaveV3Vault is ERC4626Owned {
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
  )
    ERC4626Owned(asset_, _vaultName(asset_), _vaultSymbol(asset_), feesController_, owner_)
  {
    aToken = aToken_;
    lendingPool = lendingPool_;
    rewardsController = rewardsController_;

    // Approve to lending pool all tokens
    aToken.approve(address(lendingPool), type(uint256).max);
    asset.approve(address(lendingPool), type(uint256).max);
    asset.approve(address(feesController_), type(uint256).max);
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function totalAssets() public view override returns (uint256) {
    // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
    return aToken.balanceOf(address(this));
  }

  // function _harvest(IERC20 reward)
  //   internal
  //   virtual
  //   override
  //   returns (uint256 rewardAmount)
  // {
  //   address[] memory assets = new address[](1);
  //   assets[0] = address(asset);

  //   (, uint256[] memory claimedAmounts) =
  //     rewardsController.claimAllRewards(assets, address(this));
  //   return claimedAmounts[0];
  // }

  // function _tend()
  //   internal
  //   virtual
  //   override
  //   returns (uint256 wantAmount, uint256 feesAmount)
  // {
  //   uint256 assets = asset.balanceOf(address(this));
  //   (feesAmount, wantAmount) = payFees(assets, "harvest");

  //   lendingPool.supply(address(asset), wantAmount, address(this), 0);
  // }

  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    override
    returns (uint256)
  {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Aave
    /// -----------------------------------------------------------------------
    lendingPool.withdraw(address(asset), assets, address(this));

    (, uint256 restAmount) = payFees(assets, "withdraw");

    return super.beforeWithdraw(restAmount, shares);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Aave
    /// -----------------------------------------------------------------------
    (, assets) = payFees(assets, "deposit");

    lendingPool.supply(address(asset), assets, address(this), 0);

    super.afterDeposit(assets, shares);
  }

  function maxDeposit(address owner_) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;

    if (!(_getActive(configData) && !_getFrozen(configData) && !_getPaused(configData))) {
      return 0;
    }

    // handle supply cap
    uint256 limitCap = super.maxDeposit(owner_);
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return limitCap;
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap =
      supplyCapInWholeTokens * 10 ** tokenDecimals - aToken.totalSupply();

    return limitCap < supplyCap ? limitCap : supplyCap;
  }

  function maxMint(address owner_) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
    if (!(_getActive(configData) && !_getFrozen(configData) && !_getPaused(configData))) {
      return 0;
    }

    // handle supply cap
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return super.maxMint(owner_);
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap =
      supplyCapInWholeTokens * 10 ** tokenDecimals - aToken.totalSupply();
    uint256 limitCap = super.maxDeposit(owner_);

    return convertToShares(limitCap < supplyCap ? limitCap : supplyCap);
  }

  function maxWithdraw(address owner_) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
    if (!(_getActive(configData) && !_getPaused(configData))) {
      return 0;
    }

    uint256 cash = asset.balanceOf(address(aToken));
    uint256 assetsBalance = convertToAssets(balanceOf[owner_]);
    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner_) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
    if (!(_getActive(configData) && !_getPaused(configData))) {
      return 0;
    }

    uint256 cash = asset.balanceOf(address(aToken));
    uint256 cashInShares = convertToShares(cash);
    uint256 shareBalance = balanceOf[owner_];
    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_) internal view returns (string memory vaultName) {
    vaultName = string.concat("Yasp Aave v3 Vault", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_) internal view returns (string memory vaultSymbol) {
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
}
