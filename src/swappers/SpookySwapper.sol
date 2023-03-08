// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "forge-std/interfaces/IERC20.sol";
import {Swapper} from "../Swapper.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

/// Spooky Swap Swapper
contract SpookySwapper is Swapper {
    IUniswapV2Router01 public immutable swapRouter;

    constructor(IUniswapV2Router01 swapRouter_) Swapper() {
        swapRouter = swapRouter_;
    }

    function _previewSwap(uint256 amountIn, bytes memory payload) internal view override returns (uint256) {
        address[] memory path = abi.decode(payload, (address[]));
        uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload) internal override returns (uint256 amountOut) {
        address[] memory path = abi.decode(payload, (address[]));

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

        TransferHelper.safeApprove(path[0], address(swapRouter), amountIn);

        uint256[] memory amountsOut = swapRouter.swapExactTokensForTokens(
          amountIn,
          minAmountOut,
          path,
          msg.sender,
          block.timestamp
        );

        amountOut = amountsOut[amountsOut.length - 1];
    }

    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal view override returns (bytes memory path) {
        path = abi.encodePacked(address(assetFrom), swapRouter.WETH(), address(assetTo));
    }
}
