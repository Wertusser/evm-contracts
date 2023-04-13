// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

/// Uniswap V2 Swapper
contract UniV2Swapper is Swapper, Ownable {
  IUniswapV2Router02 public immutable swapRouter;

  mapping(address => mapping(address => address[])) public paths;

  constructor(IUniswapV2Router02 swapRouter_) Swapper() Ownable() {
    swapRouter = swapRouter_;
  }

  function definePath(IERC20 assetFrom, IERC20 assetTo, address[] calldata path)
    external
    onlyOwner
  {
    paths[address(assetFrom)][address(assetTo)] = path;
  }

  function previewPath(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256 amountOut)
  {
    uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
    amountOut = amountsOut[amountsOut.length - 1];
  }

  function _generatePayload(IERC20 assetFrom, IERC20 assetTo)
    internal
    view
    override
    returns (bytes memory payload)
  {
    address[] memory path = paths[address(assetFrom)][address(assetTo)];
    payload = abi.encodePacked(path);
  }

  function _previewSwap(uint256 amountIn, bytes memory payload)
    internal
    view
    override
    returns (uint256 amountOut)
  {
    address[] memory path = abi.decode(payload, (address[]));

    uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
    amountOut = amountsOut[amountsOut.length - 1];
  }

  function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload)
    internal
    override
    returns (uint256 amountOut)
  {
    address[] memory path = abi.decode(payload, (address[]));

    IERC20 assetFrom = IERC20(path[0]);
    assetFrom.transferFrom(msg.sender, address(this), amountIn);
    assetFrom.approve(address(swapRouter), amountIn);

    uint256[] memory amountsOut = swapRouter.swapExactTokensForTokens(
      amountIn, minAmountOut, path, msg.sender, block.timestamp
    );

    amountOut = amountsOut[amountsOut.length - 1];
  }
}
