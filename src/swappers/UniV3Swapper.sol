// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Path} from "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Swapper} from "../Swapper.sol";

interface SwapRouter is ISwapRouter, IPeripheryImmutableState {}

/// Uniswap V3 Swapper
contract UniV3Swapper is Swapper {
    using Path for bytes;

    IUniswapV3Factory public immutable swapFactory;
    SwapRouter public immutable swapRouter;

    uint24 public constant POOL_FEE = 3000;

    constructor(IUniswapV3Factory swapFactory_, SwapRouter swapRouter_) Swapper() {
        swapFactory = swapFactory_;
        swapRouter = swapRouter_;
    }

    function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        address poolAddress = swapFactory.getPool(address(assetFrom), address(assetTo), POOL_FEE);
        IUniswapV3Pool singlePool = IUniswapV3Pool(poolAddress);

        if (singlePool.factory() == address(swapFactory)) {
            amountOut = _quoteSingleSwap(pool, assetFrom, assetTo, amountIn);
        } else {
            uint256 firstHop = _quoteSingleSwap(pool1, assetFrom, assetTo, amountIn);
            amountOut = _quoteSingleSwap(pool2, WETH, assetTo, firstHop);
        }
    }

    function _quoteSingleSwap(IUniswapV3Pool pool, IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
        internal
        view
        returns (uint256)
    {
        (uint160 sqrtPriceX96,,,) = singlePool.slot0();
        uint8 decimals0 = singlePool.token0() == address(assetFrom) ? assetFrom.decimals : assetTo.decimals;
        uint decimals1 = singlePool.token1() == address(assetFrom) ? assetFrom.decimals : assetTo.decimals;
        
        uint256 currentPrice = singlePool.token0() == address(assetFrom)
            ? (sqrtPriceX96 ** 2 / 2 ** 192 * 10 ** (assetTo.decimals() - assetFrom.decimals()))
            : (2 ** 192 / sqrtPriceX96 ** 2 * 10 ** (assetFrom.decimals() - assetTo.decimals()));
    }

    function _previewSwap(uint256, bytes memory) internal view override returns (uint256) {
        return 0;
    }

    function _swap(uint256 amountIn, bytes memory payload) internal override returns (uint256 amountOut) {
        (address tokenA,,) = payload.decodeFirstPool();

        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountIn);

        TransferHelper.safeApprove(tokenA, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: payload,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            // TODO: add oracle
            amountOutMinimum: 0
        });

        amountOut = swapRouter.exactInput(params);
    }

    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal view override returns (bytes memory path) {
        address poolAddress = swapFactory.getPool(address(assetFrom), address(assetTo), POOL_FEE);
        IUniswapV3Pool singlePool = IUniswapV3Pool(poolAddress);

        if (singlePool.factory() == address(swapFactory)) {
            path = abi.encodePacked(address(assetFrom), POOL_FEE, address(assetTo));
        } else {
            // optimisticly expect that pool with WETH is already exists
            path = abi.encodePacked(address(assetFrom), POOL_FEE, swapRouter.WETH9, POOL_FEE, address(assetTo));
        }
    }
}
