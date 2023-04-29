// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./external/IStargateLPStaking.sol";
import "./external/IStargateRouter.sol";
import "./external/IStargatePool.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";
import "../../periphery/ERC4626Harvest.sol";
import "../../extensions/WrapperExt.sol";

contract StargateVault is ERC4626Harvest, WrapperExt {
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
  /// @notice underlying pool asset
  address public poolToken;

  /// -----------------------------------------------------------------------
  /// Initialize
  /// -----------------------------------------------------------------------

  constructor(
    IERC20 asset_,
    IStargatePool pool_,
    IStargateRouter router_,
    IStargateLPStaking staking_,
    uint256 poolStakingId_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  )
    ERC4626Harvest(
      IERC20(address(pool_)),
      _vaultName(asset_),
      _vaultSymbol(asset_),
      swapper_,
      feesController_,
      owner_
    )
  {
    stargatePool = pool_;
    stargateRouter = router_;
    stargateLPStaking = staking_;
    poolStakingId = poolStakingId_;
    poolToken = address(asset_);

    asset_.approve(address(stargateRouter), type(uint256).max);
    stargatePool.approve(address(stargateLPStaking), type(uint256).max);
    stargatePool.approve(address(feesController_), type(uint256).max);
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------

  function _totalFunds() internal view virtual override returns (uint256) {
    IStargateLPStaking.UserInfo memory info =
      stargateLPStaking.userInfo(poolStakingId, address(this));
    return info.amount;
  }

  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    override
    returns (uint256)
  {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Stargate
    /// -----------------------------------------------------------------------

    stargateLPStaking.withdraw(poolStakingId, assets);

    (, uint256 restAmount) = payFees(assets, "withdraw");

    return super.beforeWithdraw(restAmount, shares);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Stargate
    /// -----------------------------------------------------------------------
    (, assets) = payFees(assets, "deposit");

    stargateLPStaking.deposit(poolStakingId, assets);

    super.afterDeposit(assets, shares);
  }

  function maxWithdraw(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargateLPStaking));

    uint256 assetsBalance = convertToAssets(this.balanceOf(owner_));

    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargateLPStaking));

    uint256 cashInShares = convertToShares(cash);

    uint256 shareBalance = this.balanceOf(owner_);

    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  function Harvest__collectRewards(IERC20 reward)
    internal
    override
    returns (uint256 rewardAmount)
  {
    stargateLPStaking.withdraw(poolStakingId, 0);

    rewardAmount = reward.balanceOf(address(this));
  }

  function Harvest__reinvest()
    internal
    override
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    uint256 assets = IERC20(poolToken).balanceOf(address(this));

    uint256 lpTokensBefore = stargatePool.balanceOf(address(this));
    Wrapper__wrap(IERC20(poolToken), assets);
    uint256 lpTokens = stargatePool.balanceOf(address(this)) - lpTokensBefore;

    (feesAmount, wantAmount) = payFees(lpTokens, "harvest");
    stargateLPStaking.deposit(poolStakingId, wantAmount);
  }

  function Wrapper__wrappedAsset() internal view virtual override returns (address) {
    return address(asset);
  }

  function Wrapper__wrap(IERC20, uint256 amount) internal virtual override {
    IERC20(poolToken).approve(address(stargateRouter), amount);
    stargateRouter.addLiquidity(stargatePool.poolId(), amount, address(this));
  }

  function Wrapper__unwrap(IERC20 , uint256 amount) internal virtual override {
    asset.approve(address(stargateRouter), amount);
    stargateRouter.instantRedeemLocal(uint16(stargatePool.poolId()), amount, address(this));
  }

  function Wrapper__previewWrap(IERC20 , uint256 amount)
    internal
    view
    virtual
    override
    returns (uint256 wrappedAmount)
  {
    wrappedAmount = getStargateLP(amount);
  }

  function Wrapper__previewUnwrap(IERC20 , uint256 wrappedAmount)
    internal
    view
    virtual
    override
    returns (uint256 amount)
  {
    amount = stargatePool.amountLPtoLD(wrappedAmount);
  }

  /// -----------------------------------------------------------------------
  /// Helper Stargate fuctions
  /// -----------------------------------------------------------------------

  function getStargateLP(uint256 amount_) internal view returns (uint256 lpTokens) {
    if (amount_ == 0) {
      return 0;
    }
    uint256 totalSupply_ = stargatePool.totalSupply();
    uint256 totalLiquidity_ = stargatePool.totalLiquidity();
    uint256 convertRate = stargatePool.convertRate();

    require(totalLiquidity_ > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");

    uint256 LDToSD = amount_ / convertRate;

    lpTokens = (LDToSD * totalSupply_) / totalLiquidity_;
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_) internal view returns (string memory vaultName) {
    vaultName = string.concat("Yasp Stargate Vault ", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_) internal view returns (string memory vaultSymbol) {
    vaultSymbol = string.concat("ystg", asset_.symbol());
  }
}
