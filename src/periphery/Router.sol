// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "../utils/Multicall.sol";
import { IERC4626Compoundable } from "./ERC4626Compoundable.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract Router is Multicall {
  function fundERC20(IERC20 asset, uint256 amount) public {
    asset.transferFrom(msg.sender, address(this), amount);
  }

  function sweepERC20(IERC20 asset, uint256 amount) public {
    asset.transfer(msg.sender, amount);
  }
}
