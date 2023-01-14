// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {Bytes32AddressLib} from 'solmate/utils/Bytes32AddressLib.sol';

/// Uniswap V3 Swapper
abstract contract UniSwapper is Swapper {
    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------
    function _previewSwap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn,
        bytes memory payload
    ) internal view returns (uint256 amountOut) {
      
    }

    function _swap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn,
        bytes memory payload
    ) internal returns (uint256 amountOut) {
      
    }
}
