// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import { ICurvePool } from "./external/ICurvePool.sol";
import { ICurveGauge, ICurveMinter } from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Compoundable, WithFees {
  uint8 public immutable coins;
  ///@notice curve pool contract
  ICurvePool public immutable curvePool;
  ///@notice curve gauge
  ICurveGauge public immutable curveGauge;
  ///@notice curve pool lp token
  IERC20 public immutable lpToken;
  ///@notice coin id in curve pool
  uint8 public immutable coinId;

  constructor(
    IERC20 asset_,
    IERC20 reward_,
    ICurvePool pool_,
    ICurveGauge gauge_,
    uint8 coinId_,
    uint8 coins_,
    ISwapper swapper_,
    address feesController_,
    address owner_,
    address management,
    address emergency
  )
    ERC4626Compoundable(asset_, swapper_, owner_)
    WithFees(feesController_)
  {
    curvePool = pool_;
    curveGauge = gauge_;
    lpToken = IERC20(gauge_.lp_token());

    coinId = coinId_;
    coins = coins_;

    require(pool_.coins(int128(int8(coinId))) == address(asset_));
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function totalAssets() public view override returns (uint256) {
    uint256 lpTokens = curveGauge.balanceOf(address(this));
    return curvePool.calc_withdraw_one_coin(lpTokens, int128(int8(coinId)));
  }

  function _harvest(IERC20 reward) internal override returns (uint256 rewardAmount) {
    curveGauge.claim_rewards();
    rewardAmount = reward.balanceOf(address(this));
  }

  function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
    wantAmount = _asset.balanceOf(address(this));
    sharesAdded = _zapLiquidity(wantAmount);
  }

  function beforeWithdraw(uint256 assets, uint256 /*shares*/ )
    internal
    override
    returns (uint256)
  {
    return _unzapLiquidity(assets);
  }

  function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override {
    _zapLiquidity(assets);
  }

  function maxDeposit(address owner) public view virtual override returns (uint256) {
    return !curvePool.is_killed() ? _asset.balanceOf(owner) : 0;
  }

  function maxMint(address owner) public view virtual override returns (uint256) {
    return !curvePool.is_killed() ? convertToShares(_asset.balanceOf(owner)) : 0;
  }

  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    if (curvePool.is_killed()) return 0;
    uint256 totalLiquidity = _asset.balanceOf(address(curvePool));
    uint256 assetsBalance = convertToAssets(this.balanceOf(owner));
    return totalLiquidity < assetsBalance ? totalLiquidity : assetsBalance;
  }

  function maxRedeem(address owner) public view virtual override returns (uint256) {
    if (curvePool.is_killed()) return 0;
    uint256 totalLiquidity = _asset.balanceOf(address(curvePool));
    uint256 totalLiquidityInShares = convertToShares(totalLiquidity);
    uint256 shareBalance = this.balanceOf(owner);
    return totalLiquidityInShares < shareBalance ? totalLiquidityInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// Curve integration
  /// -----------------------------------------------------------------------

  function _zapLiquidity(uint256 assets) internal returns (uint256) {
    /// -----------------------------------------------------------------------
    /// Add liquidity into Curve
    /// -----------------------------------------------------------------------
    _asset.approve(address(curvePool), assets);

    uint256[] memory amounts = new uint256[](coins);
    amounts[coinId] = assets;

    curvePool.add_liquidity(amounts, 0);

    uint256 lpTokens = lpToken.balanceOf(address(this));
    curveGauge.deposit(lpTokens);
  }

  function _unzapLiquidity(uint256 assets) internal returns (uint256) {
    /// -----------------------------------------------------------------------
    /// Remove liquidity from Curve pool imbalance
    /// -----------------------------------------------------------------------
    uint256[] memory amounts = new uint256[](coins);
    amounts[coinId] = assets;

    uint256 lpTokens = curvePool.calc_token_amount(amounts, false);

    curveGauge.withdraw(lpTokens);

    curvePool.remove_liquidity_one_coin(lpTokens, int128(int8(coinId)), 0);
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
    vaultName = string.concat("Yasp CurveFi Vault", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_)
    internal
    view
    override
    returns (string memory vaultSymbol)
  {
    vaultSymbol = string.concat("ycvx`", asset_.symbol());
  }
}
