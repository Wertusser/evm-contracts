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
  ERC20 public immutable aToken;

  /// @notice The Aave Pool contract
  IPool public immutable lendingPool;

  /// @notice The Aave RewardsController contract
  IRewardsController public immutable rewardsController;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    ERC20 asset_,
    ERC20 aToken_,
    IPool lendingPool_,
    IRewardsController rewardsController_,
    IERC20 reward_,
    ISwapper swapper_,
    FeesController feesController_,
    address keeper_,
    address management_,
    address emergency_
  )
    ERC4626Compoundable(
      asset_,
      reward_,
      swapper_,
      keeper_,
      management_,
      emergency_
    )
    WithFees(feesController_)
  {
    aToken = aToken_;
    lendingPool = lendingPool_;
    rewardsController = rewardsController_;
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function totalAssets() public view virtual override returns (uint256) {
    // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
    return aToken.balanceOf(address(this));
  }

  function beforeWithdraw(
    uint256 assets,
    uint256 /*shares*/
  ) internal virtual override returns (uint256) {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Aave
    /// -----------------------------------------------------------------------
    return lendingPool.withdraw(address(_asset), assets, address(this));
  }

  function afterDeposit(
    uint256 assets,
    uint256 /*shares*/
  ) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Aave
    /// -----------------------------------------------------------------------

    // approve to lendingPool
    _asset.approve(address(lendingPool), assets);

    // deposit into lendingPool
    // TODO: add refferal code
    lendingPool.supply(address(_asset), assets, address(this), 0);
  }

  function maxDeposit(address) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool
      .getReserveData(address(_asset))
      .configuration
      .data;
    if (
      !(_getActive(configData) &&
        !_getFrozen(configData) &&
        !_getPaused(configData))
    ) {
      return 0;
    }

    // handle supply cap
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return type(uint256).max;
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap = supplyCapInWholeTokens * 10 ** tokenDecimals;
    return supplyCap - aToken.totalSupply();
  }

  function maxMint(address) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool
      .getReserveData(address(_asset))
      .configuration
      .data;
    if (
      !(_getActive(configData) &&
        !_getFrozen(configData) &&
        !_getPaused(configData))
    ) {
      return 0;
    }

    // handle supply cap
    uint256 supplyCapInWholeTokens = _getSupplyCap(configData);
    if (supplyCapInWholeTokens == 0) {
      return type(uint256).max;
    }

    uint8 tokenDecimals = _getDecimals(configData);
    uint256 supplyCap = supplyCapInWholeTokens * 10 ** tokenDecimals;
    return convertToShares(supplyCap - aToken.totalSupply());
  }

  function maxWithdraw(
    address owner
  ) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool
      .getReserveData(address(_asset))
      .configuration
      .data;
    if (!(_getActive(configData) && !_getPaused(configData))) {
      return 0;
    }

    uint256 cash = _asset.balanceOf(address(aToken));
    uint256 assetsBalance = convertToAssets(balanceOf(owner));
    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(
    address owner
  ) public view virtual override returns (uint256) {
    // check if asset is paused
    uint256 configData = lendingPool
      .getReserveData(address(_asset))
      .configuration
      .data;
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

  function _vaultName(
    IERC20 asset_
  ) internal view override returns (string memory vaultName) {
    vaultName = string.concat('Yasp Aave v3 Vault', asset_.symbol());
  }

  function _vaultSymbol(
    IERC20 asset_
  ) internal view override returns (string memory vaultSymbol) {
    vaultSymbol = string.concat('yav3', asset_.symbol());
  }

  /// -----------------------------------------------------------------------
  /// Internal Aave functions for configData
  /// -----------------------------------------------------------------------

  function _getDecimals(uint256 configData) internal pure returns (uint8) {
    return
      uint8(
        (configData & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION
      );
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

  function _harvest()
    internal
    virtual
    override
    returns (uint256 rewardAmount)
  {}

  function _tend()
    internal
    virtual
    override
    returns (uint256 wantAmount, uint256 sharesAdded)
  {}
}
