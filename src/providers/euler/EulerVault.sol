// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.13;

// import {IERC20, ERC20} from "../../periphery/ERC20.sol";
// import {ERC4626} from "../../periphery/ERC4626.sol";
// import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

// import {IEulerEToken} from "./external/IEulerEToken.sol";

// contract EulerVault is ERC4626 {
//     /// -----------------------------------------------------------------------
//     /// Libraries usage
//     /// -----------------------------------------------------------------------

//     using SafeTransferLib for ERC20;

//     /// -----------------------------------------------------------------------
//     /// Immutable params
//     /// -----------------------------------------------------------------------

//     /// @notice The Euler main contract address
//     /// @dev Target of ERC20 approval when depositing
//     address public immutable euler;

//     /// @notice The Euler eToken contract
//     IEulerEToken public immutable eToken;

//     /// -----------------------------------------------------------------------
//     /// Constructor
//     /// -----------------------------------------------------------------------

//     constructor(ERC20 asset_, address euler_, IEulerEToken eToken_) ERC4626(asset_) {
//         euler = euler_;
//         eToken = eToken_;
//     }

//     /// -----------------------------------------------------------------------
//     /// ERC4626 overrides
//     /// -----------------------------------------------------------------------

//     function totalAssets() public view virtual override returns (uint256) {
//         return eToken.balanceOfUnderlying(address(this));
//     }

//     function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual override returns (uint256) {
//         /// -----------------------------------------------------------------------
//         /// Withdraw assets from Euler
//         /// -----------------------------------------------------------------------

//         eToken.withdraw(0, assets);
//         return 0;
//     }

//     function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
//         /// -----------------------------------------------------------------------
//         /// Deposit assets into Euler
//         /// -----------------------------------------------------------------------

//         // approve to euler
//         _asset.approve(address(euler), assets);

//         // deposit into eToken
//         eToken.deposit(0, assets);
//     }

//     function maxWithdraw(address owner) public view override returns (uint256) {
//         uint256 cash = _asset.balanceOf(euler);
//         uint256 assetsBalance = convertToAssets(balanceOf[owner]);
//         return cash < assetsBalance ? cash : assetsBalance;
//     }

//     function maxRedeem(address owner) public view override returns (uint256) {
//         uint256 cash = asset.balanceOf(euler);
//         uint256 cashInShares = convertToShares(cash);
//         uint256 shareBalance = balanceOf[owner];
//         return cashInShares < shareBalance ? cashInShares : shareBalance;
//     }

//     /// -----------------------------------------------------------------------
//     /// ERC20 metadata generation
//     /// -----------------------------------------------------------------------

//     function _vaultName(IERC20 asset_) internal view override returns (string memory vaultName) {
//         vaultName = string.concat("ERC4626-Wrapped Euler ", asset_.symbol());
//     }

//     function _vaultSymbol(IERC20 asset_) internal view override returns (string memory vaultSymbol) {
//         vaultSymbol = string.concat("we", asset_.symbol());
//     }
// }
