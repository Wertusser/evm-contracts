// SPDX-License-Identifier: MIT
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

    function _harvest() internal override returns (uint256 rewardAmount, uint256 wantAmount) {
        stargateLPStaking.withdraw(poolStakingId, 0);

        rewardAmount = reward.balanceOf(address(this));

        if (rewardAmount > 0) {
            wantAmount = swapper.swap(reward, want, rewardAmount);
        } else {
            wantAmount = 0;
        }
    }

    function previewHarvest() public view override returns (uint256) {
        uint256 pendingReward = stargateLPStaking.pendingStargate(poolStakingId, address(this));

        return swapper.previewSwap(reward, want, pendingReward);
    }

    function _tend() internal override returns (uint256 wantAmount, uint256 sharesAdded) {
        uint256 assets = want.balanceOf(address(this));
        uint256 feesAmount = feesController.onHarvest(assets);
        wantAmount = assets - feesAmount;

        sharesAdded = this.convertToShares(assets);

        stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

        uint256 lpTokens = lpToken.balanceOf(address(this));

        stargateLPStaking.deposit(poolStakingId, lpTokens);
    }

    function previewTend() public view override returns (uint256) {
        uint256 harvested = previewHarvest();
        return getStargateLP(harvested);
    }

    function deposit(uint256 assets, address receiver) public virtual override whenNotPaused returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override whenNotPaused returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);

        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets, shares);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);

        uint256 wantAmount = beforeWithdraw(assets, shares);

        _withdraw(_msgSender(), receiver, owner, wantAmount, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);

        uint256 wantAmount = beforeWithdraw(assets, shares);

        _withdraw(_msgSender(), receiver, owner, wantAmount, shares);

        return wantAmount;
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual returns (uint256) {
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

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Stargate
        /// -----------------------------------------------------------------------
        uint256 feesAmount = feesController.onDeposit(assets);
        uint256 wantAmount = assets - feesAmount;

        want.approve(address(stargateRouter), wantAmount);

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

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = want.balanceOf(address(stargatePool));

        uint256 assetsBalance = convertToAssets(this.balanceOf(owner));

        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cash = want.balanceOf(address(stargatePool));

        uint256 cashInShares = convertToShares(cash);

        uint256 shareBalance = this.balanceOf(owner);

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
