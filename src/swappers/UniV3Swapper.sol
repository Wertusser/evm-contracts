// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { Path } from "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import { IQuoter } from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IPeripheryImmutableState } from
  "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import { TransferHelper } from
  "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from
  "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV3Router is ISwapRouter, IPeripheryImmutableState { }

/// Uniswap V3 Swapper
contract UniV3Swapper is Swapper, Ownable {
  using Path for bytes;

  IUniswapV3Factory public immutable swapFactory;
  IUniswapV3Router public immutable swapRouter;

  mapping(address => mapping(address => address[])) public paths;
  mapping(address => mapping(address => uint24[])) public fees;

  constructor(IUniswapV3Factory swapFactory_, IUniswapV3Router swapRouter_)
    Swapper()
    Ownable()
  {
    swapFactory = swapFactory_;
    swapRouter = swapRouter_;
  }

  function definePath(address[] calldata path, uint24[] calldata fee) external onlyOwner {
    require(path.length - 1 == fee.length, "Error: invalid path payload");
    require(path.length >= 2, "Error: invalid path length");
    address token0 = path[0];
    address token1 = path[path.length - 1];

    paths[address(token0)][token1] = path;
    fees[address(token0)][token1] = fee;
  }

  function previewPath(uint256 amountIn, address[] calldata path, uint24[] calldata fee)
    public
    view
    returns (uint256 amountOut)
  {
    bytes memory payload = abi.encode(path[0]);

    for (uint256 i = 0; i < fee.length; i++) {
      bytes.concat(payload, bytes3(fee[i]), bytes20(path[i + 1]));
    }

    amountOut = _previewSwap(amountIn, payload);
  }

  function _quoteSingleSwap(
    IERC20 assetFrom,
    IERC20 assetTo,
    uint256 amountIn,
    uint24 tickSpacing
  ) internal view returns (uint256 amountOut) {
    IUniswapV3Pool pool = getPool(address(assetFrom), address(assetTo), tickSpacing);
    (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
    bool aToB = pool.token0() == address(assetFrom);

    uint8 decimals0 = aToB ? assetFrom.decimals() : assetTo.decimals();
    uint8 decimals1 = aToB ? assetTo.decimals() : assetFrom.decimals();
    uint256 q192 = 2 ** 192;

    if (decimals1 > decimals0) {
      uint256 decimals = 10 ** (decimals1 - decimals0);
      amountOut = aToB
        ? ((amountIn * sqrtPriceX96) / q192) * sqrtPriceX96 * decimals
        : (amountIn * q192) / sqrtPriceX96 / sqrtPriceX96 / decimals;
    } else {
      uint256 decimals = 10 ** (decimals0 - decimals1);
      amountOut = aToB
        ? (((amountIn * sqrtPriceX96) / q192) * sqrtPriceX96) / decimals
        : (amountIn * q192) / sqrtPriceX96 / sqrtPriceX96 / decimals;
    }
  }

  function _previewSwap(uint256 amountIn, bytes memory payload)
    internal
    view
    override
    returns (uint256 amountOut)
  {
    while (true) {
      (address tokenIn, address tokenOut, uint24 tickSpacing) = payload.decodeFirstPool();

      amountIn =
        _quoteSingleSwap(IERC20(tokenIn), IERC20(tokenOut), amountIn, tickSpacing);

      if (payload.hasMultiplePools()) {
        payload = payload.skipToken();
      } else {
        amountOut = amountIn;
        break;
      }
    }
  }

  function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload)
    internal
    override
    returns (uint256 amountOut)
  {
    (address tokenA,,) = payload.decodeFirstPool();

    TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountIn);

    TransferHelper.safeApprove(tokenA, address(swapRouter), amountIn);

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: payload,
      recipient: msg.sender,
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    amountOut = swapRouter.exactInput(params);
  }

  function _generatePayload(IERC20 assetFrom, IERC20 assetTo)
    internal
    view
    virtual
    override
    returns (bytes memory payload)
  {
    address[] memory path = paths[address(assetFrom)][address(assetTo)];
    uint24[] memory fee = fees[address(assetFrom)][address(assetTo)];

    payload = abi.encode(path[0]);

    for (uint256 i = 0; i < fee.length; i++) {
      bytes.concat(payload, bytes3(fee[i]), bytes20(path[i + 1]));
    }
  }

  function getPool(address token0, address token1, uint24 tickSpacing)
    internal
    view
    returns (IUniswapV3Pool pool)
  {
    (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
    pool = IUniswapV3Pool(swapFactory.getPool(token0, token1, tickSpacing));
  }
}
