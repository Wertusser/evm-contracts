// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';

import {IPool} from './external/IPool.sol';

contract StargateVault is ERC4626 {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The stargate bridge router contract
    IPool public immutable stargateRouter;
    /// @notice The stargate pool
    address public immutable poolId;
    /// @notice The stargate lp asset
    ERC20 public immutable lpToken;

    /// -----------------------------------------------------------------------
    /// Mutable params
    /// -----------------------------------------------------------------------


    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        ERC20 lpToken_,
        address poolId_,
        IPool pool_
    ) ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_)) {
        stargateRouter = router_;
        lpToken = lpToken_;
        poolId = poolId_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Withdraw assets from Stargate
        /// -----------------------------------------------------------------------

        stargateRouter.instantRedeemLocal(0, assets, address(this));
    }

    function afterDeposit(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Stargate
        /// -----------------------------------------------------------------------

        // approve to Stargate router
        asset.safeApprove(address(stargateRouter), assets);

        // deposit into stargate pool
        stargateRouter.addLiquidity(0, assets, address(this));
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(poolId);
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cash = asset.balanceOf(poolId);
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC20 asset_)
        internal
        view
        virtual
        returns (string memory vaultName)
    {
        vaultName = string.concat('ERC4626-Wrapped Stargate ', asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_)
        internal
        view
        virtual
        returns (string memory vaultSymbol)
    {
        vaultSymbol = string.concat('we', asset_.symbol());
    }
}
