// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./external/IStargateLPStaking.sol";
import "./external/IStargateRouter.sol";
import "./external/IStargatePool.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";
import "../../periphery/ERC4626Compoundable.sol";

contract StargateVault is ERC4626Compoundable, WithFees {
    /// -----------------------------------------------------------------------
    /// Params
    /// -----------------------------------------------------------------------

    /// @notice The stargate bridge router contract
    IStargateRouter public stargateRouter;
    /// @notice The stargate bridge router contract
    IStargatePool public stargatePool;
    /// @notice The stargate lp staking contract
    IStargateLPStaking public stargateLPStaking;
    /// @notice The stargate pool staking id
    uint256 public poolStakingId;
    /// @notice The stargate lp asset
    IERC20 public lpToken;

    /// -----------------------------------------------------------------------
    /// Initialize
    /// -----------------------------------------------------------------------

    constructor(
        IERC20 asset_,
        IStargatePool pool_,
        IStargateRouter router_,
        IStargateLPStaking staking_,
        uint256 poolStakingId_,
        IERC20 lpToken_,
        IERC20 reward_,
        ISwapper swapper_,
        FeesController feesController_,
        address keeper_,
        address management_,
        address emergency_
    )
        ERC4626Compoundable(asset_, reward_, swapper_, keeper_, management_, emergency_)
        WithFees(feesController_)
    {
        stargatePool = pool_;
        stargateRouter = router_;
        stargateLPStaking = staking_;
        poolStakingId = poolStakingId_;
        lpToken = lpToken_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        IStargateLPStaking.UserInfo memory info = stargateLPStaking.userInfo(poolStakingId, address(this));
        return stargatePool.amountLPtoLD(info.amount);
    }

    function _harvest() internal override returns (uint256 rewardAmount) {
        stargateLPStaking.withdraw(poolStakingId, 0);
        
        rewardAmount = reward.balanceOf(address(this));
    }

    function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
        uint256 assets = _asset.balanceOf(address(this));
        uint256 feesAmount = feesController.onHarvest(assets);
        wantAmount = assets - feesAmount;

        sharesAdded = this.convertToShares(assets);

        stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

        uint256 lpTokens = lpToken.balanceOf(address(this));

        stargateLPStaking.deposit(poolStakingId, lpTokens);
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual override returns (uint256) {
        /// -----------------------------------------------------------------------
        /// Withdraw assets from Stargate
        /// -----------------------------------------------------------------------
        uint256 feesAmount = feesController.onWithdraw(assets);
        uint256 wantAmount = assets - feesAmount;

        uint256 lpTokens = getStargateLP(wantAmount);

        stargateLPStaking.withdraw(poolStakingId, lpTokens);

        lpToken.approve(address(stargateRouter), lpTokens);

        return stargateRouter.instantRedeemLocal(uint16(stargatePool.poolId()), lpTokens, address(this));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override whenNotPaused {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Stargate
        /// -----------------------------------------------------------------------
        uint256 feesAmount = feesController.onDeposit(assets);
        uint256 wantAmount = assets - feesAmount;

        _asset.approve(address(stargateRouter), wantAmount);

        uint256 lpTokensBefore = lpToken.balanceOf(address(this));

        stargateRouter.addLiquidity(stargatePool.poolId(), wantAmount, address(this));

        uint256 lpTokensAfter = lpToken.balanceOf(address(this));

        uint256 lpTokens = lpTokensAfter - lpTokensBefore;

        lpToken.approve(address(stargateLPStaking), lpTokens);

        stargateLPStaking.deposit(poolStakingId, lpTokens);
    }

    function maxDeposit(address) public view override returns (uint256) {
        return paused() ? 0 : type(uint256).max;
    }

    function maxMint(address) public view override returns (uint256) {
        return paused() ? 0 : type(uint256).max;
    }

    function maxWithdraw(address account) public view override returns (uint256) {
        uint256 cash = _asset.balanceOf(address(stargatePool));

        uint256 assetsBalance = convertToAssets(this.balanceOf(account));

        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address account) public view override returns (uint256) {
        uint256 cash = _asset.balanceOf(address(stargatePool));

        uint256 cashInShares = convertToShares(cash);

        uint256 shareBalance = this.balanceOf(account);

        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// Internal stargate fuctions
    /// -----------------------------------------------------------------------

    function getStargateLP(uint256 amount_) internal view returns (uint256 lpTokens) {
        if (amount_ == 0) {
            return 0;
        }
        uint256 totalSupply = stargatePool.totalSupply();
        uint256 totalLiquidity = stargatePool.totalLiquidity();
        uint256 convertRate = stargatePool.convertRate();

        require(totalLiquidity > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");

        uint256 LDToSD = amount_ / convertRate;

        lpTokens = LDToSD * totalSupply / totalLiquidity;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(IERC20 asset_) internal view override returns (string memory vaultName) {
        vaultName = string.concat("Yasp Stargate Vault ", asset_.symbol());
    }

    function _vaultSymbol(IERC20 asset_) internal view override returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("ystg", asset_.symbol());
    }
}
