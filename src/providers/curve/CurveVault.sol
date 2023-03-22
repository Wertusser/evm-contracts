// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import {ICurvePool} from "./external/ICurvePool.sol";
import {ICurveGauge, ICurveMinter} from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Compoundable, WithFees {
    uint8 public constant COINS = 3;

    IERC20 public constant CRV = IERC20(address(0x0));

    ///@notice curve pool contract
    ICurvePool public immutable curvePool;
    ///@notice curve gauge
    ICurveGauge public immutable curveGauge;
    ///@notice curve gauge factory
    ICurveMinter public immutable curveGaugeFactory;
    ///@notice curve pool lp token
    IERC20 public immutable lpToken;
    ///@notice coin id in curve pool
    int128 public immutable coinId;
    ///@notice coin id in curve pool (used for array indexing)
    uint8 public immutable _coinId;

    constructor(
        IERC20 asset_,
        ICurvePool pool_,
        ICurveGauge gauge_,
        ICurveMinter factory_,
        ISwapper swapper_,
        FeesController feesController_,
        address keeper,
        address management,
        address emergency
    ) ERC4626Compoundable(asset_, CRV, swapper_, keeper, management, emergency) WithFees(feesController_) {
        curvePool = pool_;
        curveGauge = gauge_;
        curveGaugeFactory = factory_;
        lpToken = IERC20(gauge_.lp_token());
        coinId = 0;
        _coinId = 0;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------
    function totalAssets() public view override returns (uint256) {
        uint256 lpTokens = curveGauge.balanceOf(address(this));
        return curvePool.calc_withdraw_one_coin(lpTokens, coinId);
    }

    function _harvest() internal override returns (uint256 rewardAmount) {
        curveGaugeFactory.mint(address(curveGauge));
        rewardAmount = reward.balanceOf(address(this));
    }

    function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
        wantAmount = _asset.balanceOf(address(this));
        sharesAdded = _zapLiquidity(wantAmount);
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal override returns (uint256)  {
        return _unzapLiquidity(assets);
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override {
        _zapLiquidity(assets);
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return !curvePool.is_killed() ? type(uint256).max : 0;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return !curvePool.is_killed() ? type(uint256).max : 0;
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

        uint256[COINS] memory amounts;
        amounts[_coinId] = assets;

        curvePool.add_liquidity(amounts, 0);

        uint256 lpTokens = lpToken.balanceOf(address(this));
        curveGauge.deposit(lpTokens);
    }

    function _unzapLiquidity(uint256 assets) internal returns (uint256) {
        /// -----------------------------------------------------------------------
        /// Remove liquidity from Curve pool imbalance
        /// -----------------------------------------------------------------------
        uint256 lpTokens = assets;

        curveGauge.withdraw(lpTokens);

        curvePool.remove_liquidity_one_coin(lpTokens, coinId, 0);
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(IERC20 asset_) internal view override returns (string memory vaultName) {
        vaultName = string.concat("Yasp CurveFi Vault", asset_.symbol());
    }

    function _vaultSymbol(IERC20 asset_) internal view override returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("ycvx`", asset_.symbol());
    }
}
