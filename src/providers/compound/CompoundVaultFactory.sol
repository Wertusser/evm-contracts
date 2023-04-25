// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ERC4626 } from "../../periphery/ERC4626.sol";
import { CompoundVault } from "./CompoundVault.sol";
import { ERC4626Factory } from "../../periphery/ERC4626Factory.sol";
import { IComptroller } from "./external/IComptroller.sol";
import { ICERC20 } from "./external/ICERC20.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";

/// @title CompoundVaultFactory
/// @notice Factory for creating CompoundVault contracts
contract CompoundVaultFactory is ERC4626Factory {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------

  /// @notice Thrown when trying to deploy an CompoundVault vault using an asset without an aToken
  error CompoundVaultFactory__ATokenNonexistent();
  error CompoundVaultFactory__Deprecated();

  /// -----------------------------------------------------------------------
  /// Immutable params
  /// -----------------------------------------------------------------------

  /// @notice The Compound controller contract
  IComptroller public immutable comptroller;

  /// @notice Swapper contract
  ISwapper public immutable swapper;

  /// @notice fees controller
  FeesController public immutable feesController;

  address public admin;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    IComptroller comptroller_,
    ISwapper swapper_,
    FeesController feesController_
  ) {
    comptroller = comptroller_;
    swapper = swapper_;
    feesController = feesController_;
    admin = msg.sender;
  }

  /// -----------------------------------------------------------------------
  /// External functions
  /// -----------------------------------------------------------------------

  function createERC4626(ERC20 asset) external virtual returns (ERC4626 vault) {
    ICERC20 cToken = ICERC20(address(0));

    if (address(cToken) == address(0)) {
      revert CompoundVaultFactory__ATokenNonexistent();
    }

    vault = new CompoundVault{salt: bytes32(0)}(
      IERC20(address(asset)),
      cToken,
      comptroller,
      swapper,
      feesController,
      admin
    );

    emit CreateERC4626(asset, vault);
  }

  function computeERC4626Address(ERC20 asset)
    external
    view
    virtual
    returns (ERC4626 vault)
  {
    ICERC20 cToken = ICERC20(address(0));

    if (address(cToken) == address(0)) {
      revert CompoundVaultFactory__ATokenNonexistent();
    }

    vault = ERC4626(
      computeCreate2Address(
        keccak256(
          abi.encodePacked(
            // Deployment bytecode:
            type(CompoundVault).creationCode,
            // Constructor arguments:
            abi.encode(
              IERC20(address(asset)), cToken, comptroller, swapper, feesController, admin
            )
          )
        )
      )
    );
  }
}
