// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    ERC4626 as ZeppelinERC4626,
    ERC20 as ZeppelinERC20,
    IERC20 as ZeppelinIERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "forge-std/interfaces/IERC20.sol";

abstract contract ERC4626 is ZeppelinERC4626 {
  IERC20 public want;
  
    constructor(IERC20 asset_)
        ZeppelinERC20(_vaultName(asset_), _vaultSymbol(asset_))
        ZeppelinERC4626(ZeppelinIERC20(address(asset_)))
    {
      want = asset_;
    }

    function _vaultName(IERC20 asset_) internal view virtual returns (string memory vaultName);
    function _vaultSymbol(IERC20 asset_) internal view virtual returns (string memory vaultSymbol);
}
