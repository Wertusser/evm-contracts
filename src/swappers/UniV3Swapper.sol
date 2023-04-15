// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { Path } from "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IPeripheryImmutableState } from
  "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from
  "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "forge-std/interfaces/IERC20.sol";
import { Swapper } from "../periphery/Swapper.sol";
import { SafeERC20 } from "../periphery/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV3Router is ISwapRouter, IPeripheryImmutableState { }

/// Uniswap V3 Swapper
contract UniV3Swapper is Swapper, Ownable {
  using Path for bytes;

  IUniswapV3Factory public immutable swapFactory;
  IUniswapV3Router public immutable swapRouter;

  mapping(address => mapping(address => address[])) public paths;
  mapping(address => mapping(address => uint24[])) public fees;

  event PathUpdated(address indexed assetFrom, address indexed assetTo);

  constructor(IUniswapV3Factory swapFactory_, IUniswapV3Router swapRouter_)
    Swapper()
    Ownable()
  {
    swapFactory = swapFactory_;
    swapRouter = swapRouter_;
  }

  function isPathDefined(IERC20 assetFrom, IERC20 assetTo) public view returns (bool) {
    return paths[address(assetFrom)][address(assetTo)].length >= 2;
  }

  function definePath(address[] calldata path, uint24[] calldata fee) external onlyOwner {
    require(path.length - 1 == fee.length, "Error: invalid path payload");
    require(path.length >= 2, "Error: invalid path length");
    address token0 = path[0];
    address token1 = path[path.length - 1];

    paths[token0][token1] = path;
    fees[token0][token1] = fee;

    emit PathUpdated(token0, token1);
  }

  function previewPath(uint256 amountIn, address[] calldata path, uint24[] calldata fee)
    public
    view
    returns (uint256 amountOut)
  {
    require(path.length - 1 == fee.length, "Error: invalid path payload");
    require(path.length >= 2, "Error: invalid path length");

    bytes memory payload = abi.encode(path[0]);

    for (uint256 i = 0; i < fee.length; i++) {
      bytes.concat(payload, bytes3(fee[i]), bytes20(path[i + 1]));
    }

    amountOut = _previewSwap(amountIn, payload);
  }

  function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
    public
    view
    override
    returns (uint256 amountOut)
  {
    amountOut = _previewSwap(amountIn, _generatePayload(assetFrom, assetTo));
  }

  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
    public
    override
    returns (uint256 amountOut)
  {
    amountOut = _swap(amountIn, minAmountOut, _generatePayload(assetFrom, assetTo));

    emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
  }

  function _previewSwap(uint256 amountIn, bytes memory payload)
    internal
    view
    returns (uint256 amountOut)
  {
    require(amountIn <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");

    while (true) {
      (address tokenIn, address tokenOut, uint24 spacing) = payload.decodeFirstPool();

      amountIn = _quoteSingleSwap(tokenIn, tokenOut, uint128(amountIn), spacing);

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
    returns (uint256 amountOut)
  {
    (address tokenA,,) = payload.decodeFirstPool();

    SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, address(this), amountIn);

    SafeERC20.safeApprove(IERC20(tokenA), address(swapRouter), amountIn);

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
    returns (bytes memory payload)
  {
    address[] memory path = paths[address(assetFrom)][address(assetTo)];
    uint24[] memory fee = fees[address(assetFrom)][address(assetTo)];

    payload = abi.encode(path[0]);

    for (uint256 i = 0; i < fee.length; i++) {
      bytes.concat(payload, bytes3(fee[i]), bytes20(path[i + 1]));
    }
  }

  // ============= Uniswap utility ===============

  function _quoteSingleSwap(
    address assetFrom,
    address assetTo,
    uint128 amountIn,
    uint24 tickSpacing
  ) internal view returns (uint256 amountOut) {
    IUniswapV3Pool pool = _getPool(assetFrom, assetTo, tickSpacing);

    (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

    if (sqrtPriceX96 <= type(uint128).max) {
      uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
      amountOut = assetFrom < assetTo
        ? mulDiv(ratioX192, amountIn, 1 << 192)
        : mulDiv(1 << 192, amountIn, ratioX192);
    } else {
      uint256 ratioX128 = mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
      amountOut = assetFrom < assetTo
        ? mulDiv(ratioX128, amountIn, 1 << 128)
        : mulDiv(1 << 128, amountIn, ratioX128);
    }
  }

  function _getPool(address token0, address token1, uint24 tickSpacing)
    internal
    view
    returns (IUniswapV3Pool pool)
  {
    (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);

    pool = IUniswapV3Pool(swapFactory.getPool(token0, token1, tickSpacing));
  }

  function mulDiv(uint256 a, uint256 b, uint256 denominator)
    internal
    pure
    returns (uint256 result)
  {
    uint256 prod0;
    uint256 prod1;
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    require(denominator > prod1);

    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    uint256 twos = (~denominator + 1) & denominator;
    assembly {
      denominator := div(denominator, twos)
      prod0 := div(prod0, twos)
      twos := add(div(sub(0, twos), twos), 1)
    }

    prod0 |= prod1 * twos;

    uint256 inv = (3 * denominator) ^ 2;

    inv *= 2 - denominator * inv;
    inv *= 2 - denominator * inv;
    inv *= 2 - denominator * inv;
    inv *= 2 - denominator * inv;
    inv *= 2 - denominator * inv;
    inv *= 2 - denominator * inv;

    result = prod0 * inv;
    return result;
  }
}
