// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/interfaces/IERC20.sol";
import {Swapper} from "../../src/periphery/Swapper.sol";
import {ERC20Mock} from "./ERC20.m.sol";


contract SwapperMock is Swapper {
    ERC20Mock public token0;
    ERC20Mock public token1;

    constructor(ERC20Mock token0_, ERC20Mock token1_) Swapper() {
        token0 = token0_;
        token1 = token1_;
    }

    function _previewSwap(uint256 amountIn, bytes memory) internal pure override returns (uint256) {
        return amountIn;
    }

    function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
        public
        override
        returns (uint256)
    {   
        bool aToB = address(token0) == address(assetFrom);
        
        ERC20Mock tokenFrom = aToB ? token0 : token1;
        ERC20Mock tokenTo = aToB ? token1 : token0;
        tokenFrom.burn(msg.sender, amountIn);
        tokenTo.mint(msg.sender, amountIn);
        return minAmountOut;
    }

    function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload)
        internal
        override
        returns (uint256 amountOut)
    {
        amountOut = amountIn;
    }

    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal view override returns (bytes memory path) {
        path = abi.encodePacked(address(assetFrom), address(assetTo));
    }
}
