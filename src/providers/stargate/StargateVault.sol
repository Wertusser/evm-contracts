// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./external/IStargateLPStaking.sol";
import "./external/IStargateRouter.sol";
import "./external/IStargatePool.sol";
import {UniV3Swapper} from "../../swappers/UniV3Swapper.sol";

// TODO:
// - Events
// - Tests (proxy, spec, invariant)
// - Mocks
// - validate updates
// - Research: UUPSUpgradeable
// - Fees

contract StargateVault is Initializable, ERC4626Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// -----------------------------------------------------------------------
    /// Params
    /// -----------------------------------------------------------------------

    /// @notice want asset
    ERC20 public want;
    /// @notice The stargate bridge router contract
    IStargateRouter public stargateRouter;
    /// @notice The stargate bridge router contract
    IStargatePool public stargatePool;
    /// @notice The stargate lp staking contract
    IStargateLPStaking public stargateLPStaking;
    /// @notice The stargate pool staking id
    uint256 public poolStakingId;
    /// @notice The stargate lp asset
    ERC20 public lpToken;
    /// @notice The stargate expected reward token (prob. STG or OP)
    ERC20 public reward;
    // @notice Swapper contract
    UniV3Swapper public swapper;

    event Harvest(address indexed executor, uint256 amountReward, uint256 amountWant);
    event Tend(address indexed executor, uint256 amountWant, uint256 amountShares);

    /// -----------------------------------------------------------------------
    /// Initialize
    /// -----------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }

    function initialize(
        ERC20Upgradeable asset_,
        IStargateRouter router_,
        IStargatePool pool_,
        IStargateLPStaking staking_,
        uint256 poolStakingId_,
        ERC20 lpToken_,
        ERC20 reward_,
        UniV3Swapper swapper_
    ) public initializer {
        __ERC4626_init(asset_);
        __Ownable_init();
        __UUPSUpgradeable_init();

        want = ERC20(address(asset_));
        stargateRouter = router_;
        stargatePool = pool_;
        stargateLPStaking = staking_;
        poolStakingId = poolStakingId_;
        lpToken = lpToken_;
        reward = reward_;
        swapper = swapper_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // TODO: write migrateToNewImplementation
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        IStargateLPStaking.UserInfo memory info = stargateLPStaking.userInfo(poolStakingId, address(this));
        return stargatePool.amountLPtoLD(info.amount);
    }

    function harvest() public returns (uint256) {
        stargateLPStaking.withdraw(poolStakingId, 0);
        uint256 rewardAmount = reward.balanceOf(address(this));
        uint256 wantAmount = swapper.swap(reward, want, rewardAmount);

        emit Harvest(msg.sender, rewardAmount, wantAmount);

        return wantAmount;
    }

    function previewHarvest() public view returns (uint256) {
        uint256 pendingReward = stargateLPStaking.pendingStargate(poolStakingId, address(this));

        return swapper.previewSwap(reward, want, pendingReward);
    }

    function tend() public returns (uint256) {
        uint256 wantAmount = want.balanceOf(address(this));

        uint256 shares = this.convertToShares(wantAmount);

        stargateRouter.addLiquidity(stargatePool.poolId(), wantAmount, address(this));

        uint256 lpTokens = lpToken.balanceOf(address(this));

        stargateLPStaking.deposit(poolStakingId, lpTokens);

        emit Tend(msg.sender, wantAmount, shares);

        return lpTokens;
    }

    function previewTend() public view returns (uint256) {
        uint256 harvested = previewHarvest();
        return getStargateLP(harvested);
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);

        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets, shares);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);

        beforeWithdraw(assets, shares);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);

        beforeWithdraw(assets, shares);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal virtual {
        /// -----------------------------------------------------------------------
        /// Withdraw assets from Stargate
        /// -----------------------------------------------------------------------
        uint256 lpTokens = getStargateLP(assets);

        stargateLPStaking.withdraw(poolStakingId, lpTokens);

        stargateRouter.instantRedeemLocal(stargatePool.poolId(), assets, address(this));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Stargate
        /// -----------------------------------------------------------------------
        stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

        uint256 lpTokens = lpToken.balanceOf(address(this));

        stargateLPStaking.deposit(poolStakingId, lpTokens);
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = want.balanceOf(address(stargatePool));

        uint256 assetsBalance = convertToAssets(this.balanceOf(owner));

        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        // FIX: use pool cash
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

    function _vaultName(ERC20 asset_) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("ERC4626-Wrapped Stargate ", asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("ysg", asset_.symbol());
    }
}
