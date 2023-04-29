// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Harvest.sol";
import "../../extensions/WrapperExt.sol";
import { ICurvePool } from "./external/ICurvePool.sol";
import { ICurveGauge, ICurveMinter } from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Harvest, WrapperExt {
  ///@notice curve gauge
  ICurveGauge public immutable curveGauge;
  ///@notice curve pool contract
  ICurvePool public immutable curvePool;
  ///@notice total coins in curve pool
  uint8 public immutable coins;
  ///@notice curve pool asset that used in Harvest-tend flow
  IERC20 public redeemAsset;
  ///@notice coin id in curve pool
  IERC20 private lpToken;

  mapping(address => uint8) addressToId;

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

    coins = coins_;

    for (uint8 i = 0; i < coins; i++) {
      addressToId[_getPoolCoin(i)] = i;
    }

    redeemAsset = IERC20(_getPoolCoin(0));

    lpToken.approve(address(gauge_), type(uint256).max);
    lpToken.approve(address(feesController_), type(uint256).max);
  }

  function setRedeemAsset(uint8 coinId_) public onlyOwner {
    redeemAsset = IERC20(_getPoolCoin(coinId_));
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function _totalFunds() internal view override returns (uint256) {
    return curveGauge.balanceOf(address(this));
  }

  function afterDeposit(uint256 assets, uint256 shares) internal override {
    (, assets) = payFees(assets, "deposit");

    curveGauge.deposit(assets);

    super.afterDeposit(assets, shares);
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

  function Wrapper__wrappedAsset() internal view virtual override returns (address) {
    return address(asset);
  }

  function Wrapper__wrap(IERC20 assetFrom, uint256 amount) internal virtual override {
    assetFrom.approve(address(curvePool), amount);
    uint8 coinId = addressToId[address(assetFrom)];

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 5) {
      uint256[5] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }

    if (coins == 6) {
      uint256[6] memory coinsAmount;
      coinsAmount[coinId] = amount;
      uint256 expectedLp = curvePool.calc_token_amount(coinsAmount, true);
      curvePool.add_liquidity(coinsAmount, (expectedLp * 99) / 100);
    }
  }

  function Wrapper__unwrap(IERC20 assetTo, uint256 amount) internal virtual override {
    uint8 coinId = addressToId[address(assetTo)];

    try curvePool.remove_liquidity_one_coin(amount, coinId, 0) { }
    catch {
      curvePool.remove_liquidity_one_coin(amount, int128(int8(coinId)), 0);
    }
  }

  function Wrapper__previewWrap(IERC20 assetFrom, uint256 amount)
    internal
    view
    virtual
    override
    returns (uint256 wrappedAmount)
  {
    uint8 coinId = addressToId[address(assetFrom)];

    if (coins == 2) {
      uint256[2] memory coinsAmount;
      coinsAmount[coinId] = amount;
      wrappedAmount = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 3) {
      uint256[3] memory coinsAmount;
      coinsAmount[coinId] = amount;
      wrappedAmount = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 4) {
      uint256[4] memory coinsAmount;
      coinsAmount[coinId] = amount;
      wrappedAmount = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 5) {
      uint256[5] memory coinsAmount;
      coinsAmount[coinId] = amount;
      wrappedAmount = curvePool.calc_token_amount(coinsAmount, true);
    }

    if (coins == 6) {
      uint256[6] memory coinsAmount;
      coinsAmount[coinId] = amount;
      wrappedAmount = curvePool.calc_token_amount(coinsAmount, true);
    }
  }

  function Wrapper__previewUnwrap(IERC20 assetTo, uint256 wrappedAmount)
    internal
    view
    virtual
    override
    returns (uint256 amount)
  {
    uint8 coinId = addressToId[address(assetTo)];
    try curvePool.calc_withdraw_one_coin(wrappedAmount, coinId) returns (uint256 assets_)
    {
      amount = assets_;
    } catch {
      amount = curvePool.calc_withdraw_one_coin(wrappedAmount, int128(int8(coinId)));
    }
  }

  function Harvest__collectRewards(IERC20 reward)
    internal
    override
    returns (uint256 rewardAmount)
  {
    curveGauge.claim_rewards();
    rewardAmount = reward.balanceOf(address(this));
  }

  function Harvest__reinvest()
    internal
    override
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    uint256 assets = redeemAsset.balanceOf(address(this));
    redeemAsset.approve(address(curvePool), assets);
    uint256 lpTokensBefore = lpToken.balanceOf(address(this));

    Wrapper__wrap(redeemAsset, assets);

    uint256 lpTokens = lpToken.balanceOf(address(this)) - lpTokensBefore;

    (feesAmount, wantAmount) = payFees(lpTokens, "harvest");

    curveGauge.deposit(wantAmount);
  }

  /// -----------------------------------------------------------------------
  /// Helper Curve fuctions
  /// -----------------------------------------------------------------------

  function _getPoolCoin(uint8 coinId) internal view returns (address) {
    try curvePool.coins(coinId) returns (address token) {
      return token;
    } catch {
      try curvePool.coins(int128(int8(coinId))) returns (address token) {
        return token;
      } catch {
        return address(0);
      }
    }
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
