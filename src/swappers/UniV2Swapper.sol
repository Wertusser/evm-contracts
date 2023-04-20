// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";
import "solmate/auth/Owned.sol";

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
contract UniV2Swapper is Swapper, Owned {
  IUniswapV2Router02 public immutable swapRouter;

  mapping(address => mapping(address => address[])) public paths;

  constructor(IUniswapV2Router02 swapRouter_) Swapper() Owned(msg.sender) {
    swapRouter = swapRouter_;
  }

  function isPathDefined(IERC20 assetFrom, IERC20 assetTo) public view returns (bool) {
    return paths[address(assetFrom)][address(assetTo)].length >= 2;
  }

  function definePath(IERC20 assetFrom, IERC20 assetTo, address[] calldata path)
    external
    onlyOwner
  {
    paths[address(assetFrom)][address(assetTo)] = path;

    assetFrom.approve(address(swapRouter), type(uint256).max);
  }

  function previewPath(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256 amountOut)
  {
    uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
    amountOut = amountsOut[amountsOut.length - 1];
  }

  function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
    public
    view
    override
    returns (uint256 amountOut)
  {
    require(isPathDefined(assetFrom, assetTo), "Error: path is not defined");

    address[] memory path = paths[address(assetFrom)][address(assetTo)];

    uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
    amountOut = amountsOut[amountsOut.length - 1];
  }

  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
    public
    override
    returns (uint256 amountOut)
  {
    require(isPathDefined(assetFrom, assetTo), "Error: path is not defined");

    address[] memory path = paths[address(assetFrom)][address(assetTo)];

    assetFrom.transferFrom(msg.sender, address(this), amountIn);

    uint256[] memory amountsOut = swapRouter.swapExactTokensForTokens(
      amountIn, minAmountOut, path, msg.sender, block.timestamp
    );

    amountOut = amountsOut[amountsOut.length - 1];

    emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
  }
}
