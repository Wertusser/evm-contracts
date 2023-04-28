// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
import { ERC4626 } from "./ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

abstract contract ERC4626Owned is ERC4626, Owned {
  /// @notice Maximum deposit limit
  uint256 public depositLimit = 1e27;
  /// @notice if emergencyMode is true, user can only withdraw assets
  bool public emergencyMode = false;

  event DepositLimitUpdated(uint256 depositLimit);
  event EmergencyUpdated(bool value);
  event MetadataUpdated(string name, string symbol);
  event Sweep(address token, address receiver, uint256 amount);

  constructor(IERC20 asset_, string memory _name, string memory _symbol, address admin_)
    ERC4626(ERC20(address(asset_)), _name, _symbol)
    Owned(admin_)
  { }

  function setEmergency(bool emergencyMode_) public onlyOwner {
    emergencyMode = emergencyMode_;

    emit EmergencyUpdated(emergencyMode);
  }

  function setDepositLimit(uint256 depositLimit_) public onlyOwner {
    require(depositLimit_ >= totalAssets());
    depositLimit = depositLimit_;

    emit DepositLimitUpdated(depositLimit);
  }

  function setMetadata(string memory name_, string memory symbol_) public onlyOwner {
    name = name_;
    symbol = symbol_;

    emit MetadataUpdated(name_, symbol_);
  }

  function sweep(address tokenAddress, address receiver, uint256 amount)
    external
    onlyOwner
  {
    require(tokenAddress != address(asset), "Cannot withdraw the underlying token");
    IERC20(tokenAddress).transfer(receiver, amount);

    emit Sweep(tokenAddress, receiver, amount);
  }

  function sweepETH(address payable receiver, uint256 amount) external payable onlyOwner {
    (bool s,) = receiver.call{ value: amount }("");
    require(s, "ETH transfer failed");

    emit Sweep(address(0), receiver, amount);
  }

  function maxDeposit(address) public view virtual override returns (uint256) {
    if (depositLimit >= totalAssets() && !emergencyMode) {
      return depositLimit - totalAssets();
    } else {
      return 0;
    }
  }

  function maxMint(address) public view virtual override returns (uint256) {
    if (depositLimit >= totalAssets() && !emergencyMode) {
      return convertToShares(depositLimit - totalAssets());
    } else {
      return 0;
    }
  }
}
