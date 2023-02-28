// // SPDX-License-Identifier: AGPL-3.0
// pragma solidity ^0.8.13;

// import {ERC20} from 'solmate/tokens/ERC20.sol';
// import {ERC4626} from 'solmate/mixins/ERC4626.sol';
// import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
// import {ICurvePool} from './external/ICurvePool.sol';

// contract CurveVault is ERC4626 {
//     using SafeTransferLib for ERC20;

//     ICurvePool public immutable pool;
//     ERC20 public immutable lpToken;

//     constructor(
//         ERC20 asset_,
//         ICurvePool pool_,
//         ERC20 lpToken_
//     ) ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_)) {
//         pool = pool_;
//         lpToken = lpToken_;
//     }

//     /// -----------------------------------------------------------------------
//     /// ERC4626 overrides
//     /// -----------------------------------------------------------------------
//     function totalAssets() public view virtual override returns (uint256) {
//         return lpToken.balanceOf(address(this));
//     }

//     function beforeWithdraw(
//         uint256 assets,
//         uint256 /*shares*/
//     ) internal virtual override {
//         /// -----------------------------------------------------------------------
//         /// Remove liquidity from Curve pool imbalance
//         /// -----------------------------------------------------------------------
//         pool.remove_liquidity_one_coin(assets, 0, assets);
//     }

//     function afterDeposit(
//         uint256 assets,
//         uint256 /*shares*/
//     ) internal virtual override {
//         /// -----------------------------------------------------------------------
//         /// Add liquidity into Curve
//         /// -----------------------------------------------------------------------

//         // approve to lendingPool
//         asset.safeApprove(address(pool), assets);

//         pool.add_liquidity([uint256(0), uint256(0), uint256(0), uint256(0)], assets);
//     }

//     function maxDeposit(address)
//         public
//         view
//         virtual
//         override
//         returns (uint256)
//     {
//         return !pool.is_killed() ? type(uint256).max : 0;
//     }

//     function maxMint(address) public view virtual override returns (uint256) {
//         return !pool.is_killed() ? type(uint256).max : 0;
//     }

//     function maxWithdraw(address owner)
//         public
//         view
//         virtual
//         override
//         returns (uint256)
//     {
//         if (pool.is_killed()) return 0;
//         uint256 totalLiquidity = asset.balanceOf(address(pool));
//         uint256 assetsBalance = convertToAssets(balanceOf[owner]);
//         return totalLiquidity < assetsBalance ? totalLiquidity : assetsBalance;
//     }

//     function maxRedeem(address owner)
//         public
//         view
//         virtual
//         override
//         returns (uint256)
//     {
//         if (pool.is_killed()) return 0;
//         uint256 totalLiquidity = asset.balanceOf(address(pool));
//         uint256 totalLiquidityInShares = convertToShares(totalLiquidity);
//         uint256 shareBalance = balanceOf[owner];
//         return
//             totalLiquidityInShares < shareBalance
//                 ? totalLiquidityInShares
//                 : shareBalance;
//     }

//     /// -----------------------------------------------------------------------
//     /// ERC20 metadata generation
//     /// -----------------------------------------------------------------------

//     function _vaultName(ERC20 asset_)
//         internal
//         view
//         virtual
//         returns (string memory vaultName)
//     {
//         vaultName = string.concat('Yasp CurveFi Vault', asset_.symbol());
//     }

//     function _vaultSymbol(ERC20 asset_)
//         internal
//         view
//         virtual
//         returns (string memory vaultSymbol)
//     {
//         vaultSymbol = string.concat('ycvx`', asset_.symbol());
//     }
// }
