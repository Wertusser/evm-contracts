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
    ERC4626Compoundable(asset_, _vaultName(asset_), _vaultSymbol(asset_), swapper_, owner_)
    WithFees(feesController_)
  {
    stargatePool = pool_;
    stargateRouter = router_;
    stargateLPStaking = staking_;
    poolStakingId = poolStakingId_;
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------

  function _totalAssets() internal view virtual override returns (uint256) {
    IStargateLPStaking.UserInfo memory info =
      stargateLPStaking.userInfo(poolStakingId, address(this));
    return stargatePool.amountLPtoLD(info.amount);
  }

  function _harvest(IERC20 reward) internal override returns (uint256 rewardAmount) {
    stargateLPStaking.withdraw(poolStakingId, 0);

    rewardAmount = reward.balanceOf(address(this));
  }

  function _tend() internal override returns (uint256 wantAmount, uint256 feesAmount) {
    uint256 assets = asset.balanceOf(address(this));
    (, wantAmount) = payFees(assets, "harvest");

    asset.approve(address(stargateRouter), assets);

    uint256 lpTokensBefore = stargatePool.balanceOf(address(this));

    stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

    uint256 lpTokensAfter = stargatePool.balanceOf(address(this));

    uint256 lpTokens = lpTokensAfter - lpTokensBefore;

    stargateLPStaking.deposit(poolStakingId, lpTokens);
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal override {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Stargate
    /// -----------------------------------------------------------------------
    // (, assets) = payFees(assets, "withdraw");
    super.beforeWithdraw(assets, shares);

    uint256 lpTokens = getStargateLP(assets);

    stargateLPStaking.withdraw(poolStakingId, lpTokens);

    stargatePool.approve(address(stargateRouter), lpTokens);

    stargateRouter.instantRedeemLocal(
      uint16(stargatePool.poolId()), lpTokens, address(this)
    );
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Stargate
    /// -----------------------------------------------------------------------
    // (, assets) = payFees(assets, "deposit");

    asset.approve(address(stargateRouter), assets);

    uint256 lpTokensBefore = stargatePool.balanceOf(address(this));

    stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

    uint256 lpTokensAfter = stargatePool.balanceOf(address(this));

    uint256 lpTokens = lpTokensAfter - lpTokensBefore;

    stargatePool.approve(address(stargateLPStaking), lpTokens);

    stargateLPStaking.deposit(poolStakingId, lpTokens);

    super.afterDeposit(assets, shares);
  }

  function maxDeposit(address) public view override returns (uint256) {
    return canDeposit ? depositLimit - totalAssets() : 0;
  }

  function maxMint(address) public view override returns (uint256) {
    return canDeposit ? convertToShares(depositLimit - totalAssets()) : 0;
  }

  function maxWithdraw(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargatePool));

    uint256 assetsBalance = convertToAssets(this.balanceOf(owner_));

    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargatePool));

    uint256 cashInShares = convertToShares(cash);

    uint256 shareBalance = this.balanceOf(owner_);

    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// Internal stargate fuctions
  /// -----------------------------------------------------------------------

  function getStargateLP(uint256 amount_) internal view returns (uint256 lpTokens) {
    if (amount_ == 0) {
      return 0;
    }
    uint256 totalSupply_ = stargatePool.totalSupply();
    uint256 totalLiquidity = stargatePool.totalLiquidity();
    uint256 convertRate = stargatePool.convertRate();

    require(totalLiquidity > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");

    uint256 LDToSD = amount_ / convertRate;

    lpTokens = LDToSD * totalSupply_ / totalLiquidity;
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
