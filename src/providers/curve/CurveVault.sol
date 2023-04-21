// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import { ICurvePool } from "./external/ICurvePool.sol";
import { ICurveGauge, ICurveMinter } from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Compoundable, WithFees {
  ///@notice curve gauge
  ICurveGauge public immutable curveGauge;
  ///@notice curve pool contract
  ICurvePool public immutable curvePool;
  ///@notice total coins in curve pool
  uint8 public immutable coins;
  ///@notice coin id in curve pool
  uint8 public coinId;

  constructor(
    ICurveGauge gauge_,
    ICurvePool pool_,
    uint8 coins_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  )
    ERC4626Compoundable(
      IERC20(gauge_.lp_token()),
      _vaultName(IERC20(gauge_.lp_token())),
      _vaultSymbol(IERC20(gauge_.lp_token())),
      swapper_,
      owner_
    )
    WithFees(feesController_)
  {
    curvePool = pool_;
    curveGauge = gauge_;

    coinId = 0;
    coins = coins_;

    require(coinId < coins);
    require(curvePool.token() == curveGauge.lp_token());
  }

  function setCoinId(uint8 id) public onlyOwner {
    coinId = id;
  }

  function underlyingAsset() public view returns (address) {
    return curvePool.coins(int128(int8(coinId)));
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function _totalAssets() internal view override returns (uint256) {
    return curveGauge.balanceOf(address(this));
  }

  function harvest(IERC20 reward, uint256 swapAmountOut)
    public
    override
    onlyKeeper
    returns (uint256 rewardAmount, uint256 wantAmount)
  {
    _harvest(reward);
    rewardAmount = reward.balanceOf(address(this));

    if (rewardAmount > 0) {
      reward.approve(address(swapper), rewardAmount);
      wantAmount =
        swapper.swap(reward, IERC20(underlyingAsset()), rewardAmount, swapAmountOut);
    } else {
      wantAmount = 0;
    }

    emit Harvest(rewardAmount, wantAmount);
  }

  function _harvest(IERC20 reward) internal override returns (uint256 rewardAmount) {
    curveGauge.claim_rewards();
    rewardAmount = reward.balanceOf(address(this));
  }

  function _tend() internal override returns (uint256 wantAmount, uint256 feesAmount) {
    IERC20 underlying = IERC20(underlyingAsset());
    IERC20 lpToken = IERC20(curvePool.token());

    uint256 assets = underlying.balanceOf(address(this));

    uint256[] memory coinsAmount = new uint256[](coins);
    coinsAmount[coinId] = assets;

    uint256 lpTokensBefore = lpToken.balanceOf(address(this));

    uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
    curvePool.add_liquidity(coinsAmount, expectedLp);

    uint256 lpTokens = lpToken.balanceOf(address(this)) - lpTokensBefore;

    (feesAmount, wantAmount) = payFees(lpTokens, "harvest");

    curveGauge.deposit(wantAmount);
  }

  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    override
    returns (uint256)
  {
    curveGauge.withdraw(assets);

    (, uint256 restAmount) = payFees(assets, "withdraw");

    return super.beforeWithdraw(restAmount, shares);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal override {
    (, assets) = payFees(assets, "deposit");

    curveGauge.deposit(assets);

    super.afterDeposit(assets, shares);
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_) internal view returns (string memory vaultName) {
    vaultName = string.concat("Yasp CurveFi Vault ", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_) internal view returns (string memory vaultSymbol) {
    vaultSymbol = string.concat("ycvx`", asset_.symbol());
  }
}
