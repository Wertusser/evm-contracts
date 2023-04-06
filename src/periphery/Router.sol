// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "../utils/Multicall.sol";
import { IERC4626Compoundable } from "./ERC4626Compoundable.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract Router is Multicall {
  constructor() { }

  function harvest(address vault, address reward, uint256 minAmountOut)
    public
    returns (uint256 wantAmount)
  {
    wantAmount = IERC4626Compoundable(vault).harvest(IERC20(reward), minAmountOut);
  }

  function tend(address vault) public {
    IERC4626Compoundable(vault).tend();
  }

  function harvestTend(address vault, address reward, uint256 minAmountOut)
    public
    returns (uint256 wantAmount)
  {
    wantAmount = harvest(vault, reward, minAmountOut);
    tend(vault);
  }
}
