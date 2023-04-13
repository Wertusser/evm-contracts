// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";

contract DummySwapper is Swapper, Ownable {
  address public receiver;

  constructor() Swapper() Ownable() {
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

  function _previewSwap(uint256, bytes memory) internal pure override returns (uint256) {
    return 0;
  }

  function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload)
    internal
    override
    returns (uint256 amountOut)
  {
    amountOut = 0;
  }

  function _generatePayload(IERC20 assetFrom, IERC20 assetTo)
    internal
    view
    virtual
    override
    returns (bytes memory payload)
  { }
}
