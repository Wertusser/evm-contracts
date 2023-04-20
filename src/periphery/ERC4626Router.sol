// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "../utils/Multicall.sol";
import "../utils/PeripheryPayments.sol";
import "../utils/SelfPermit.sol";
import { IERC4626, IERC4626Compoundable } from "./ERC4626Compoundable.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint256 weth) external;
}

interface IERC2612 is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

contract ERC4626Router is Multicall, PeripheryPayments, SelfPermit {
  IERC20 constant NATIVE_TOKEN = IERC20(address(0));
  uint8 internal _entered = 1;

  IWETH public immutable WETH;

  modifier nonReentrant() {
    require(_entered == 1, "Error: reentrant call");
    _entered = 2;
    _;
    _entered = 1;
  }

  constructor(IWETH weth) PeripheryPayments(weth) {
    WETH = weth;
  }

  function depositVault(IERC4626 vault, uint256 assets, address receiver)
    public
    nonReentrant
    returns (uint256 shares)
  {
    IERC20(vault.asset()).approve(address(vault), assets);
    shares = vault.deposit(assets, receiver);
  }

  function mintVault(IERC4626 vault, uint256 shares, address receiver)
    public
    nonReentrant
    returns (uint256 assets)
  {
    IERC20(vault.asset()).approve(address(vault), vault.convertToShares(assets));

    assets = vault.mint(shares, receiver);
  }

  function withdrawVault(IERC4626 vault, uint256 assets, address receiver)
    public
    nonReentrant
    returns (uint256 shares)
  {
    shares = vault.withdraw(assets, receiver, address(this));
  }

  function redeemVault(IERC4626 vault, uint256 shares, address receiver)
    public
    nonReentrant
    returns (uint256 assets)
  {
    assets = vault.redeem(shares, receiver, address(this));
  }

  function depositToVault(
    IERC4626 vault,
    address to,
    uint256 amount,
    uint256 minSharesOut
  ) external payable override returns (uint256 sharesOut) {
    pullToken(ERC20(vault.asset()), amount, address(this));
    return deposit(vault, to, amount, minSharesOut);
  }

  function withdrawToDeposit(
    IERC4626 fromVault,
    IERC4626 toVault,
    address to,
    uint256 amount,
    uint256 maxSharesIn,
    uint256 minSharesOut
  ) external payable override returns (uint256 sharesOut) {
    withdraw(fromVault, address(this), amount, maxSharesIn);
    return deposit(toVault, to, amount, minSharesOut);
  }

  function redeemToDeposit(
    IERC4626 fromVault,
    IERC4626 toVault,
    address to,
    uint256 shares,
    uint256 minSharesOut
  ) external payable override returns (uint256 sharesOut) {
    // amount out passes through so only one slippage check is needed
    uint256 amount = redeem(fromVault, address(this), shares, 0);
    return deposit(toVault, to, amount, minSharesOut);
  }

  function depositMax(IERC4626 vault, address to, uint256 minSharesOut)
    public
    payable
    override
    returns (uint256 sharesOut)
  {
    ERC20 asset = ERC20(vault.asset());
    uint256 assetBalance = asset.balanceOf(msg.sender);
    uint256 maxDeposit = vault.maxDeposit(to);
    uint256 amount = maxDeposit < assetBalance ? maxDeposit : assetBalance;
    pullToken(asset, amount, address(this));
    return deposit(vault, to, amount, minSharesOut);
  }

  function redeemMax(IERC4626 vault, address to, uint256 minAmountOut)
    public
    payable
    override
    returns (uint256 amountOut)
  {
    uint256 shareBalance = vault.balanceOf(msg.sender);
    uint256 maxRedeem = vault.maxRedeem(msg.sender);
    uint256 amountShares = maxRedeem < shareBalance ? maxRedeem : shareBalance;
    return redeem(vault, to, amountShares, minAmountOut);
  }
}
