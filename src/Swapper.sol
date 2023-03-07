// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

/// @title Swapper
/// @notice Abstract base contract for deploying wrappers for AMMs
/// @dev
abstract contract Swapper {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @notice Emitted when a new swap has been executed
    /// @param from The base asset
    /// @param to The quote asset
    /// @param amountIn amount that has been swapped
    /// @param amountOut received amount
    event Swap(address indexed sender, IERC20 indexed from, IERC20 indexed to, uint256 amountIn, uint256 amountOut);

    function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) external virtual view returns (uint256 amountOut) {
        bytes memory payload = _buildPayload(assetFrom, assetTo);

        amountOut = _previewSwap(amountIn, payload);
    }

    function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) external virtual returns (uint256 amountOut) {
        bytes memory payload = _buildPayload(assetFrom, assetTo);

        amountOut = _swap(amountIn, payload);

        emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------
    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal virtual view returns (bytes memory path);

    function _previewSwap(uint256 amountIn, bytes memory payload) internal virtual view returns (uint256 amountOut);

    function _swap(uint256 amountIn, bytes memory payload) internal virtual returns (uint256 amountOut);
}
