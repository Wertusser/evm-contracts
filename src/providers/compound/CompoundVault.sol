// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import "./external/ICERC20.sol";
import "./external/IComptroller.sol";
import "./external/libCompound.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";
import "../../periphery/ERC4626Compoundable.sol";

contract CompoundVault is ERC4626Compoundable, WithFees {
  /// -----------------------------------------------------------------------
  /// Libraries usage
  /// -----------------------------------------------------------------------

  using LibCompound for ICERC20;
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;

  /// -----------------------------------------------------------------------
  /// Immutable params
  /// -----------------------------------------------------------------------

  /// @notice The Compound cToken contract
  ICERC20 public immutable cToken;

  /// @notice The Compound comptroller contract
  IComptroller public immutable comptroller;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    IERC20 asset_,
    ICERC20 cToken_,
    IComptroller comptroller_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  )
    ERC4626Compoundable(asset_, _vaultName(asset_), _vaultSymbol(asset_), swapper_, owner_)
    WithFees(feesController_)
  {
    cToken = cToken_;
    comptroller = comptroller_;

    // Approve to lending pool all tokens
    asset.approve(address(cToken), type(uint256).max);
    asset.approve(address(feesController_), type(uint256).max);
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------
  function _totalAssets() internal view virtual override returns (uint256) {
    return cToken.viewUnderlyingBalanceOf(address(this));
  }

  function _harvest(IERC20 reward)
    internal
    virtual
    override
    returns (uint256 rewardAmount)
  {
    comptroller.claimVenus(address(this));

    return reward.balanceOf(address(this));
  }

  function _tend()
    internal
    virtual
    override
    returns (uint256 wantAmount, uint256 feesAmount)
  {
    uint256 assets = asset.balanceOf(address(this));
    (feesAmount, wantAmount) = payFees(assets, "harvest");

    uint256 errorCode = cToken.mint(wantAmount);
    require(errorCode == 0, "Compound Error");
  }

  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    virtual
    override
    returns (uint256)
  {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Compound
    /// -----------------------------------------------------------------------

    uint256 errorCode = cToken.redeemUnderlying(assets);
    require(errorCode == 0, "Compound Error");

    (, uint256 restAmount) = payFees(assets, "withdraw");

    return super.beforeWithdraw(restAmount, shares);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Compound
    /// -----------------------------------------------------------------------

    (, assets) = payFees(assets, "deposit");

    uint256 errorCode = cToken.mint(assets);
    require(errorCode == 0, "Compound Error");

    super.afterDeposit(assets, shares);
  }

  function maxDeposit(address) public view override returns (uint256) {
    if (comptroller.mintGuardianPaused(cToken)) return 0;
    return depositLimit - totalAssets();
  }

  function maxMint(address) public view override returns (uint256) {
    if (comptroller.mintGuardianPaused(cToken)) return 0;
    return depositLimit - totalAssets();
  }

  function maxWithdraw(address owner) public view override returns (uint256) {
    uint256 cash = cToken.getCash();
    uint256 assetsBalance = convertToAssets(balanceOf[owner]);
    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner) public view override returns (uint256) {
    uint256 cash = cToken.getCash();
    uint256 cashInShares = convertToShares(cash);
    uint256 shareBalance = balanceOf[owner];
    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_) internal view returns (string memory vaultName) {
    vaultName = string.concat("Yasp Compound Vault", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_) internal view returns (string memory vaultSymbol) {
    vaultSymbol = string.concat("ycomp", asset_.symbol());
  }
}
