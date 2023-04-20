// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "../utils/Multicall.sol";
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

abstract contract Router is Multicall {
  IERC20 constant NATIVE_TOKEN = IERC20(address(0));
  uint8 internal _entered = 1;

  IWETH public immutable WETH;

  modifier nonReentrant() {
    require(_entered == 1, "Error: reentrant call");
    _entered = 2;
    _;
    _entered = 1;
  }
  constructor(IWETH weth) {
    WETH = weth;
  }

  function wrap(uint256 ethAmount) public payable {
    WETH.deposit{ value: ethAmount }();
  }

  function unwrap(uint256 wethAmount) public payable {
    WETH.withdraw(wethAmount);
  }

  function permit(
    address asset,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public nonReentrant {
    require(asset != address(0), "Error: invalid ERC-2612 token");
    IERC2612 token = IERC2612(asset);

    token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    token.transferFrom(msg.sender, address(this), amount);
  }

  function fund(IERC20 asset, uint256 amount) public payable nonReentrant {
    if (asset != NATIVE_TOKEN) {
      asset.transferFrom(msg.sender, address(this), amount);
    }
  }

  function sweep(IERC20 asset, uint256 amount, address receiver) public payable nonReentrant {
    if (asset != NATIVE_TOKEN) {
      asset.transfer(receiver, amount);
    } else {
      (bool s,) = receiver.call{ value: amount }("");
      require(s, "ETH transfer failed");
    }
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

  receive() external payable { }
}
