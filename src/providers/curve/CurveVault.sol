// // SPDX-License-Identifier: AGPL-3.0
// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {ICurvePool} from './external/ICurvePool.sol';

// contract CurveVault is Initializable, ERC4626Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
//     ERC20Upgradeable public immutable want;
//     ICurvePool public immutable curvePool;
//     ERC20 public immutable lpToken;
//     ERC20 public immutable lpToken;

//     constructor() {
//         _disableInitializers();
//     }

//     function initialize(
//         ERC20Upgradeable asset_,
//         ICurvePool pool_,
//         ERC20 lpToken_,
//         ERC20 reward_
//     ) public initializer {
//         __ERC4626_init(asset_);
//         __Ownable_init();
//         __UUPSUpgradeable_init();

//         want = asset_;
//         stargatePool = pool_;
//         lpToken = lpToken_;
//         reward = reward_;
//     }

//     function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
//         // TODO: write migrateToNewImplementation
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
