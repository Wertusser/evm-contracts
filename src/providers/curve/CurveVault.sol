// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import {ICurvePool} from "./external/ICurvePool.sol";
import {ICurveGauge} from "./external/ICurveGauge.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Compoundable, WithFees {
    ///@notice curve pool contract
    ICurvePool public immutable curvePool;
    ///@notice curve gauge
    ICurveGauge public immutable curveGauge;
    ///@notice curve pool lp token
    IERC20 public immutable lpToken;
    ///@notice coin id in curve pool
    uint8 public immutable coinId;
    ///@notice amount of supported coins in curve pool
    uint8 public immutable poolSize;

    constructor(
        IERC20 asset_,
        ICurvePool pool_,
        uint8 coinId_,
        uint8 poolSize_,
        ICurveGauge gauge_,
        IERC20 lpToken_,
        IERC20 reward_,
        ISwapper swapper_,
        FeesController feesController_,
        address keeper,
        address management,
        address emergency
    ) ERC4626Compoundable(asset_, reward_, swapper_, keeper, management, emergency) WithFees(feesController_) {
        curvePool = pool_;
        curveGauge = gauge_;
        lpToken = lpToken_;
        coinId = coinId_;
        poolSize = poolSize_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------
    function totalAssets() public view override returns (uint256) {
        uint256 lpTokens = curveGauge.balanceOf(address(this));
        return curvePool.calc_withdraw_one_coin(lpTokens, coinId);
    }

    function _harvest() internal override returns (uint256 rewardAmount, uint256 wantAmount) {
        rewardAmount = curvePool.claimable_tokens(address(this));

        if (rewardAmount > 0) {
            wantAmount = swapper.swap(reward, want, rewardAmount);
        } else {
            wantAmount = 0;
        }
    }

    function previewHarvest() public view override returns (uint256) {
        return 0;
    }

    function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
        wantAmount = want.balanceOf(address(this));
        sharesAdded = _zapLiquidity(wantAmount);
    }

    function previewTend() public view override returns (uint256) {
        return 0;
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal {
        _unzapLiquidity(assets);
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal {
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
        uint256 totalLiquidity = want.balanceOf(address(curvePool));
        uint256 assetsBalance = convertToAssets(this.balanceOf(owner));
        return totalLiquidity < assetsBalance ? totalLiquidity : assetsBalance;
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        if (curvePool.is_killed()) return 0;
        uint256 totalLiquidity = want.balanceOf(address(curvePool));
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
        want.approve(address(curvePool), assets);
        
        uint256[] memory amounts = new uint256[](poolSize);
        amounts[coinId] = assets;

        uint256 lpTokens = curvePool.add_liquidity(amounts, 0);

        curveGauge.deposit(lpTokens);
    }

    function _unzapLiquidity(uint256 assets) internal returns (uint256) {
         /// -----------------------------------------------------------------------
        /// Remove liquidity from Curve pool imbalance
        /// -----------------------------------------------------------------------
        uint256 lpTokens = assets;

        curvePool.withdraw(lpTokens);

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
