// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {EulerVault} from "./EulerVault.sol";
import {IEulerMarkets} from "./external/IEulerMarkets.sol";
import {IEulerEToken} from "./external/IEulerEToken.sol";
import {ERC4626Factory} from "../../ERC4626Factory.sol";

/// @title EulerVaultFactory
/// @notice Factory for creating EulerVault contracts
contract EulerVaultFactory is ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to deploy an EulerVault vault using an asset without an eToken
    error EulerVaultFactory__ETokenNonexistent();

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Euler main contract address
    /// @dev Target of ERC20 approval when depositing
    address public immutable euler;

    /// @notice The Euler markets module address
    IEulerMarkets public immutable markets;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address euler_, IEulerMarkets markets_) {
        euler = euler_;
        markets = markets_;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ERC4626Factory
    function createERC4626(ERC20 asset) external virtual override returns (ERC4626 vault) {
        address eTokenAddress = markets.underlyingToEToken(address(asset));
        if (eTokenAddress == address(0)) {
            revert EulerVaultFactory__ETokenNonexistent();
        }

        vault = new EulerVault{salt: bytes32(0)}(asset, euler, IEulerEToken(eTokenAddress));

        emit CreateERC4626(asset, vault);
    }

    /// @inheritdoc ERC4626Factory
    function computeERC4626Address(ERC20 asset) external view virtual override returns (ERC4626 vault) {
        vault = ERC4626(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        // Deployment bytecode:
                        type(EulerVault).creationCode,
                        // Constructor arguments:
                        abi.encode(asset, euler, IEulerEToken(markets.underlyingToEToken(address(asset))))
                    )
                )
            )
        );
    }
}