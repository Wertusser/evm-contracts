// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./ERC20.sol";
import { SafeERC20 } from "./SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20 {
  event Deposit(
    address indexed sender, address indexed owner, uint256 assets, uint256 shares
  );

  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /**
   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
   *
   * - MUST be an ERC-20 token contract.
   * - MUST NOT revert.
   */
  function asset() external view returns (address assetTokenAddress);

  /**
   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
   *
   * - SHOULD include any compounding that occurs from yield.
   * - MUST be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT revert.
   */
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /**
   * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToShares(uint256 assets) external view returns (uint256 shares);

  /**
   * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToAssets(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
   * through a deposit call.
   *
   * - MUST return a limited value if receiver is subject to some deposit limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
   * - MUST NOT revert.
   */
  function maxDeposit(address receiver) external view returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
   *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
   *   in the same transaction.
   * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
   *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewDeposit(uint256 assets) external view returns (uint256 shares);

  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   deposit execution, and are accounted for during deposit.
   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
   * - MUST return a limited value if receiver is subject to some mint limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
   * - MUST NOT revert.
   */
  function maxMint(address receiver) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
   *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
   *   same transaction.
   * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
   *   would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by minting.
   */
  function previewMint(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
   *   execution, and are accounted for during mint.
   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function mint(uint256 shares, address receiver) external returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
   * Vault, through a withdraw call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
   *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
   *   called
   *   in the same transaction.
   * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
   *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewWithdraw(uint256 assets) external view returns (uint256 shares);

  /**
   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   withdraw execution, and are accounted for during withdraw.
   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
   * through a redeem call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxRedeem(address owner) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
   *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
   *   same transaction.
   * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
   *   redemption would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
   */
  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   redeem execution, and are accounted for during redeem.
   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function redeem(uint256 shares, address receiver, address owner)
    external
    returns (uint256 assets);
}

abstract contract ERC4626 is ERC20, IERC4626 {
  using Math for uint256;

  IERC20 public immutable _asset;
  uint8 private immutable _underlyingDecimals;

  /**
   * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
   */
  constructor(IERC20 asset_)
    ERC20(_vaultName(asset_), _vaultSymbol(asset_), asset_.decimals())
  {
    (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
    _underlyingDecimals = success ? assetDecimals : 18;
    _asset = asset_;
  }

  /**
   * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
   */
  function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
    (bool success, bytes memory encodedDecimals) =
      address(asset_).staticcall(abi.encodeWithSelector(IERC20.decimals.selector));
    if (success && encodedDecimals.length >= 32) {
      uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
      if (returnedDecimals <= type(uint8).max) {
        return (true, uint8(returnedDecimals));
      }
    }
    return (false, 0);
  }

  function _vaultName(IERC20 asset_)
    internal
    view
    virtual
    returns (string memory vaultName);
  function _vaultSymbol(IERC20 asset_)
    internal
    view
    virtual
    returns (string memory vaultSymbol);

  /**
   * @dev See {IERC4626-asset}.
   */
  function asset() public view virtual override returns (address) {
    return address(_asset);
  }

  /**
   * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
   * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
   * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
   *
   * See {IERC20Metadata-decimals}.
   */
  function decimals() public view virtual override(IERC20, ERC20) returns (uint8) {
    return _underlyingDecimals + _decimalsOffset();
  }

  /**
   * @dev See {IERC4626-totalAssets}.
   */
  function totalAssets() public view virtual override returns (uint256) {
    return _asset.balanceOf(address(this));
  }

  /**
   * @dev See {IERC4626-convertToShares}.
   */
  function convertToShares(uint256 assets)
    public
    view
    virtual
    override
    returns (uint256 shares)
  {
    return _convertToShares(assets, Math.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-convertToAssets}.
   */
  function convertToAssets(uint256 shares)
    public
    view
    virtual
    override
    returns (uint256 assets)
  {
    return _convertToAssets(shares, Math.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-maxDeposit}.
   */
  function maxDeposit(address) public view virtual override returns (uint256) {
    return _isVaultCollateralized() ? type(uint256).max : 0;
  }

  /**
   * @dev See {IERC4626-maxMint}.
   */
  function maxMint(address) public view virtual override returns (uint256) {
    return type(uint256).max;
  }

  /**
   * @dev See {IERC4626-maxWithdraw}.
   */
  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-maxRedeem}.
   */
  function maxRedeem(address owner) public view virtual override returns (uint256) {
    return balanceOf(owner);
  }

  /**
   * @dev See {IERC4626-previewDeposit}.
   */
  function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-previewMint}.
   */
  function previewMint(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Up);
  }

  /**
   * @dev See {IERC4626-previewWithdraw}.
   */
  function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, Math.Rounding.Up);
  }

  /**
   * @dev See {IERC4626-previewRedeem}.
   */
  function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, Math.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-deposit}.
   */
  function deposit(uint256 assets, address receiver)
    public
    virtual
    override
    returns (uint256)
  {
    require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

    uint256 shares = previewDeposit(assets);

    _deposit(_msgSender(), receiver, assets, shares);

    afterDeposit(assets, shares);

    return shares;
  }

  /**
   * @dev See {IERC4626-mint}.
   *
   * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
   * In this case, the shares will be minted without requiring any assets to be deposited.
   */
  function mint(uint256 shares, address receiver)
    public
    virtual
    override
    returns (uint256)
  {
    require(shares <= maxMint(receiver), "ERC4626: mint more than max");

    uint256 assets = previewMint(shares);

    _deposit(_msgSender(), receiver, assets, shares);

    afterDeposit(assets, shares);

    return assets;
  }

  /**
   * @dev See {IERC4626-withdraw}.
   */
  function withdraw(uint256 assets, address receiver, address account)
    public
    virtual
    override
    returns (uint256)
  {
    require(assets <= maxWithdraw(account), "ERC4626: withdraw more than max");

    uint256 shares = previewWithdraw(assets);

    uint256 wantAmount = beforeWithdraw(assets, shares);

    _withdraw(_msgSender(), receiver, account, wantAmount, shares);

    return shares;
  }

  /**
   * @dev See {IERC4626-redeem}.
   */
  function redeem(uint256 shares, address receiver, address account)
    public
    virtual
    override
    returns (uint256)
  {
    require(shares <= maxRedeem(account), "ERC4626: redeem more than max");

    uint256 assets = previewRedeem(shares);

    uint256 wantAmount = beforeWithdraw(assets, shares);

    _withdraw(_msgSender(), receiver, account, wantAmount, shares);

    return wantAmount;
  }

  /**
   * @dev Internal conversion function (from assets to shares) with support for rounding direction.
   *
   * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
   * would represent an infinite amount of shares.
   */
  /**
   * @dev Internal conversion function (from assets to shares) with support for rounding direction.
   */
  function _convertToShares(uint256 assets, Math.Rounding rounding)
    internal
    view
    virtual
    returns (uint256)
  {
    return
      assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
  }

  /**
   * @dev Internal conversion function (from shares to assets) with support for rounding direction.
   */
  function _convertToAssets(uint256 shares, Math.Rounding rounding)
    internal
    view
    virtual
    returns (uint256)
  {
    return
      shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
  }

  /**
   * @dev Deposit/mint common workflow.
   */
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    virtual
  {
    // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
    // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
    // calls the vault, which is assumed not malicious.
    //
    // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
    // assets are transferred and before the shares are minted, which is a valid state.
    // slither-disable-next-line reentrancy-no-eth
    SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
    _mint(receiver, shares);

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Withdraw/redeem common workflow.
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }

    // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
    // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
    // calls the vault, which is assumed not malicious.
    //
    // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
    // shares are burned and after the assets are transferred, which is a valid state.
    _burn(owner, shares);
    SafeERC20.safeTransfer(_asset, receiver, assets);

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  /**
   * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
   */
  function _isVaultCollateralized() private view returns (bool) {
    return totalAssets() > 0 || totalSupply() == 0;
  }

  function _decimalsOffset() internal view virtual returns (uint8) {
    return 0;
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual;
  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    virtual
    returns (uint256);
}
