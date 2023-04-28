// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Harvest.sol";
import { ICurvePool } from "./external/ICurvePool.sol";
import { ICurveGauge, ICurveMinter } from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Harvest {
  ///@notice curve gauge
  ICurveGauge public immutable curveGauge;
  ///@notice curve pool contract
  ICurvePool public immutable curvePool;
  ///@notice total coins in curve pool
  uint8 public immutable coins;
  ///@notice coin id in curve pool
  uint8 public coinId;
  ///@notice coin id in curve pool
  IERC20 private lpToken;

  constructor(
    ICurveGauge gauge_,
    ICurvePool pool_,
    uint8 coins_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  )
    ERC4626Harvest(
      IERC20(gauge_.lp_token()),
      _vaultName(IERC20(gauge_.lp_token())),
      _vaultSymbol(IERC20(gauge_.lp_token())),
      swapper_,
      feesController_,
      owner_
    )
  {
    try pool_.token() returns (address lpTokenAddress) {
      lpToken = IERC20(lpTokenAddress);
    } catch {
      lpToken = IERC20(address(pool_));
    }

    require(address(lpToken) == gauge_.lp_token());

    curvePool = pool_;
    curveGauge = gauge_;

    coinId = 0;
    coins = coins_;

    lpToken.approve(address(gauge_), type(uint256).max);
    lpToken.approve(address(feesController_), type(uint256).max);
  }

  function setCoinId(uint8 id) public onlyOwner {
    coinId = id;
  }

  function underlyingAsset() public view returns (address) {
    try curvePool.coins(coinId) returns (address token) {
      return token;
    } catch {
      return curvePool.coins(int128(int8(coinId)));
    }
  }

  /// -----------------------------------------------------------------------
  /// Deposit/Wihtdraw Helpers
  /// -----------------------------------------------------------------------
  function zapDeposit(uint256 assets, uint8 coinId_, address receiver)
    public
    returns (uint256 shares)
  {
    IERC20 depositAsset = IERC20(curvePool.coins(coinId_));
    depositAsset.transferFrom(msg.sender, address(this), assets);
    depositAsset.approve(address(curvePool), assets);

    uint256 lpTokensBefore = lpToken.balanceOf(address(this));

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

    uint256 lpTokens = lpToken.balanceOf(address(this)) - lpTokensBefore;

    lpToken.transfer(msg.sender, lpTokens);

    shares = super.deposit(lpTokens, receiver);
  }

  function zapWithdraw(uint256 assets, uint8 coinId_, address receiver, address owner_)
    public
    returns (uint256 shares)
  {
    IERC20 withdrawAsset = IERC20(curvePool.coins(coinId_));

    uint256 lpTokensBefore = lpToken.balanceOf(address(this));

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      assets = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      assets = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId_] = assets;
      assets = curvePool.calc_token_amount(coinsAmount, true);
    }

    shares = super.withdraw(assets, address(this), owner_);

    uint256 lpTokens = lpToken.balanceOf(address(this)) - lpTokensBefore;

    uint256 withdrawAmountBefore = withdrawAsset.balanceOf(address(this));

    try curvePool.remove_liquidity_one_coin(lpTokens, coinId_, 0) { }
    catch {
      curvePool.remove_liquidity_one_coin(lpTokens, int128(int8(coinId_)), 0);
    }

    uint256 withdrawAmount = withdrawAsset.balanceOf(address(this)) - withdrawAmountBefore;

    withdrawAsset.transfer(receiver, withdrawAmount);
  }

  function maxZapWithdraw(address owner_, uint8 coinId_)
    public
    view
    returns (uint256 assets)
  {
    uint256 withdrawal = maxWithdraw(owner_);
    try curvePool.calc_withdraw_one_coin(withdrawal, coinId_) returns (uint256 assets_) {
      return assets_;
    } catch {
      return curvePool.calc_withdraw_one_coin(withdrawal, int128(int8(coinId_)));
    }
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function _totalFunds() internal view override returns (uint256) {
    return curveGauge.balanceOf(address(this));
  }

  function Harvest__collectRewards(IERC20 reward) internal override returns (uint256 rewardAmount) {
    curveGauge.claim_rewards();
    rewardAmount = reward.balanceOf(address(this));
  }

  function Harvest__reinvest() internal override returns (uint256 wantAmount, uint256 feesAmount) {
    IERC20 underlying = IERC20(underlyingAsset());
    uint256 assets = underlying.balanceOf(address(this));
    underlying.approve(address(curvePool), assets);

    uint256 lpTokensBefore = lpToken.balanceOf(address(this));

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId] = assets;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, expectedLp * 99 / 100);
    }

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
    vaultSymbol = string.concat("ycrv`", asset_.symbol());
  }
}
