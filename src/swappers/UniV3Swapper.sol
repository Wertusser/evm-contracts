// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Path} from '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {IQuoter} from '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {Swapper} from '../Swapper.sol';

/// Uniswap V3 Swapper
contract UniV3Swapper is Swapper {
    using Path for bytes;

    ISwapRouter public immutable swapRouter;
    IQuoter public immutable quoter;

    constructor(ISwapRouter swapRouter_, IQuoter quoter_) Swapper() {
        swapRouter = swapRouter_;
        quoter = quoter_;
    }

    function _validatePayload(bytes calldata payload)
        internal
        override
        returns (bytes32[8] memory formattedPayload)
    {
        formattedPayload = abi.decode(payload, (bytes32[8]));
        bytes memory path = abi.encodePacked(formattedPayload);
        uint256 amountOut = quoter.quoteExactInput(path, 1e18);
        require(amountOut > 0, 'Swap path is not valid');
    }

    function _previewSwap(uint256 amountIn, bytes32[8] memory payload)
        internal
        override
        returns (uint256 amountOut)
    {
        bytes memory path = abi.encodePacked(payload);
        amountOut = quoter.quoteExactInput(path, amountIn);
    }

    function _swap(uint256 amountIn, bytes32[8] memory payload)
        internal
        override
        returns (uint256 amountOut)
    {
        bytes memory path = abi.encodePacked(payload);
        (address tokenA, , ) = path.decodeFirstPool();
        
        TransferHelper.safeTransferFrom(
            tokenA,
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(tokenA, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        amountOut = swapRouter.exactInput(params);
    }
}
