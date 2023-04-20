// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";

contract DummySwapper is Swapper, Owned {
  address public receiver;

  constructor() Swapper() Owned(msg.sender) {
    receiver = msg.sender;
  }

  function setReceiver(address newReceiver) public onlyOwner {
    receiver = newReceiver;
  }

  function previewSwap(
    IERC20,
    /* assetTo */
    IERC20,
    /* assetTo */
    uint256 amountIn
  ) public view override returns (uint256) {
    return amountIn;
  }

  function swap(
    IERC20 assetFrom,
    IERC20,
    /* assetTo */
    uint256 amountIn,
    uint256 /* minAmountOut */
  ) public override returns (uint256) {
    assetFrom.transferFrom(msg.sender, receiver, amountIn);
    return 0;
  }
}
