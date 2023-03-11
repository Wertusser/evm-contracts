// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../../periphery/ERC4626Compoundable.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/ERC4626Compoundable.sol";
import {ICurvePool} from "./external/ICurvePool.sol";
import "forge-std/interfaces/IERC20.sol";

contract CurveVault is ERC4626Compoundable, WithFees, Pausable {
    ICurvePool public immutable curvePool;
    IERC20 public immutable lpToken;

    constructor(
        IERC20 asset_,
        ICurvePool pool_,
        IERC20 lpToken_,
        IERC20 reward_,
        ISwapper swapper_,
        FeesController feesController_,
        address admin
    ) ERC4626Compoundable(asset_, reward_, swapper_, admin) WithFees(feesController_) Pausable() {
        curvePool = pool_;
        lpToken = lpToken_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------
    function totalAssets() public view override returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function _harvest() internal override returns (uint256 rewardAmount, uint256 wantAmount) {
        rewardAmount = 0;

        wantAmount = 0;
    }

    function previewHarvest() public view override returns (uint256) {
        return 0;
    }

    function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
        wantAmount = 0;

        sharesAdded = 0;
    }

    function previewTend() public view override returns (uint256) {
        return 0;
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal {
        /// -----------------------------------------------------------------------
        /// Remove liquidity from Curve pool imbalance
        /// -----------------------------------------------------------------------
        curvePool.remove_liquidity_one_coin(assets, 0, assets);
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal {
        /// -----------------------------------------------------------------------
        /// Add liquidity into Curve
        /// -----------------------------------------------------------------------

        // approve to lendingPool
        want.approve(address(curvePool), assets);

        curvePool.add_liquidity([uint256(0), uint256(0), uint256(0), uint256(0)], assets);
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
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(IERC20 asset_) internal view override returns (string memory vaultName) {
        vaultName = string.concat("Yasp CurveFi Vault", asset_.symbol());
    }

    function _vaultSymbol(IERC20 asset_) internal view override returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("ycvx`", asset_.symbol());
    }
}
