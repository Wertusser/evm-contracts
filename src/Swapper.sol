// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC4626} from 'solmate/mixins/ERC4626.sol';
import {Bytes32AddressLib} from 'solmate/utils/Bytes32AddressLib.sol';

/// @title Swapper
/// @notice Abstract base contract for deploying wrappers for AMMs
/// @dev
abstract contract Swapper {
    // keccak(sender, from, to) => route payload
    mapping(bytes32 => bytes) public routes;
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
        ERC20 indexed from,
        ERC4626 indexed to,
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
    function getRouteId(address sender, ERC20 assetFrom, ERC20 assetTo)
        external
        view
        returns (bytes32 id)
    {
        return keccak256(abi.encodePacked(sender, assetFrom, assetTo));
    }

    /// @notice Set a swap route for asset pair for sender
    /// @dev
    /// @param assetFrom The base asset
    /// @param assetTo The quote asset
    function setRoute(
        ERC20 assetFrom,
        ERC20 assetTo,
        bytes calldata payload
    ) external returns (bytes32 id) {
        bytes8 id = getRouteId(msg.sender, assetFrom, assetTo);
        require(_validatePayload(payload), "Payload isn't valid");
        routes[id] = payload;
    }

    function previewSwap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        bytes8 id = getRouteId(msg.sender, assetFrom, assetTo);
        bytes memory payload = routes[id];

        uint256 amountOut = _previewSwap(assetFrom, assetTo, amountIn, payload);
    }

    function swap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        bytes8 id = getRouteId(msg.sender, assetFrom, assetTo);
        bytes memory payload = routes[id];

        uint256 amountOut = _swap(assetFrom, assetTo, amountIn, payload);

        emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------
    function _validatePayload(bytes calldata payload)
        internal
        view
        virtual
        returns (boolean isValid)
    {
        return true;
    }

    function _previewSwap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn,
        bytes memory payload
    ) internal view virtual returns (uint256 amountOut);

    function _swap(
        ERC20 assetFrom,
        ERC20 assetTo,
        uint256 amountIn,
        bytes memory payload
    ) internal virtual returns (uint256 amountOut);
}
