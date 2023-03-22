// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import {Swapper} from "../periphery/Swapper.sol";

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

/// Spooky Swap Swapper
contract SpookySwapper is Swapper {
    IUniswapV2Router02 public immutable swapRouter;

    constructor(IUniswapV2Router02 swapRouter_) Swapper() {
        swapRouter = swapRouter_;
    }

    function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
        public
        override
        returns (uint256 amountOut)
    {
        address[] memory path = new address[](2);
        path[0] = address(assetFrom);
        path[1] = address(assetTo);

        assetFrom.transferFrom(msg.sender, address(this), amountIn);
        assetFrom.approve(address(swapRouter), amountIn);

        uint256[] memory amountsOut =
            swapRouter.swapExactTokensForTokens(amountIn, minAmountOut, path, msg.sender, block.timestamp);

        amountOut = amountsOut[amountsOut.length - 1];

        emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
    }

    function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
        public
        view
        override
        returns (uint256 amountOut)
    {
        address[] memory path = new address[](2);
        path[0] = address(assetFrom);
        path[1] = address(assetTo);

        uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
        amountOut =  amountsOut[amountsOut.length - 1];
    }



    function _previewSwapWithPath(uint256 amountIn, address[] memory path) internal view returns (uint256) {}

    function _buildPath(IERC20 assetFrom, IERC20 assetTo) internal view returns (address[] memory path) {}

    function _previewSwap(uint256 amountIn, bytes memory payload) internal view override returns (uint256) {}

    function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload)
        internal
        override
        returns (uint256 amountOut)
    {}

    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal view override returns (bytes memory payload) {}
}
