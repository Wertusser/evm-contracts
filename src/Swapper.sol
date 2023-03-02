// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Bytes32AddressLib} from 'solmate/utils/Bytes32AddressLib.sol';

/// @title Swapper
/// @notice Abstract base contract for deploying wrappers for AMMs
/// @dev
abstract contract Swapper {
    // keccak(from, to) => route payload
    mapping(bytes32 => bytes32[8]) public routes;
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
    event Swap(
        address indexed sender,
        IERC20 indexed from,
        IERC20 indexed to,
        uint256 amountIn,
        uint256 amountOut
    );

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Set a swap route for asset pair for sender
    /// @dev
    /// @param assetFrom The base asset
    /// @param assetTo The quote asset
    function getRouteId(
        IERC20 assetFrom,
        IERC20 assetTo
    ) public pure returns (bytes32 id) {
        return keccak256(abi.encodePacked(assetFrom, assetTo));
    }

    /// @notice Get a swap route for asset pair for sender
    /// @dev
    /// @param assetFrom The base asset
    /// @param assetTo The quote asset
    function getRoute(IERC20 assetFrom, IERC20 assetTo)
        public
        view
        returns (bytes32[8] memory payload)
    {
        bytes32 id = getRouteId(assetFrom, assetTo);
        payload = routes[id];
    }

    /// @notice Set a swap route for asset pair for sender
    /// @dev
    /// @param assetFrom The base asset
    /// @param assetTo The quote asset
    function setRoute(
        IERC20 assetFrom,
        IERC20 assetTo,
        bytes calldata payload
    ) external returns (bytes32 id) {
        id = getRouteId(assetFrom, assetTo);
        bytes32[8] memory formattedPayload = _validatePayload(payload);
        routes[id] = formattedPayload;
    }

    function previewSwap(
        IERC20 assetFrom,
        IERC20 assetTo,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        bytes32[8] memory payload = getRoute(assetFrom, assetTo);

        amountOut = _previewSwap(amountIn, payload);
    }

    function swap(
        IERC20 assetFrom,
        IERC20 assetTo,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        bytes32[8] memory payload = getRoute(assetFrom, assetTo);

        amountOut = _swap(amountIn, payload);

        emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------
    function _validatePayload(bytes calldata payload)
        internal
        virtual
        returns (bytes32[8] memory formattedPayload);

    function _previewSwap(
        uint256 amountIn,
        bytes32[8] memory payload
    ) internal virtual returns (uint256 amountOut);

    function _swap(
        uint256 amountIn,
        bytes32[8] memory payload
    ) internal virtual returns (uint256 amountOut);
}
