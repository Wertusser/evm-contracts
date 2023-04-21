// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { CurveVault } from "./CurveVault.sol";
import { ERC4626Factory } from "../../periphery/ERC4626Factory.sol";
import { ERC4626 } from "../../periphery/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import "./external/ICurveGauge.sol";
import "./external/ICurvePool.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";

/// @title CurveVaultFactory
/// @notice Factory for creating CurveVault contracts
contract CurveVaultFactory is ERC4626Factory {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------

  error CurveVaultFactory__PoolNonexistent();
  error CurveVaultFactory__StakingNonexistent();
  error CurveVaultFactory__Deprecated();

  /// @notice Swapper contract
  ISwapper public immutable swapper;
  /// @notice fees controller
  FeesController public immutable feesController;

  address public admin;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(FeesController feesController_, ISwapper swapper_, address admin_) {
    swapper = swapper_;
    feesController = feesController_;
    admin = admin_;
  }

  /// -----------------------------------------------------------------------
  /// External functions
  /// -----------------------------------------------------------------------
  function createERC4626(
    ICurveGauge gauge_,
    ICurvePool pool_,
    uint8 coins_
  ) external returns (ERC4626 vault) {
    vault = new CurveVault{salt: bytes32(0)}(
          gauge_,
          pool_,
          coins_,
          swapper,
          feesController,
          admin
        );

    emit CreateERC4626(ERC20(gauge_.lp_token()), vault);
  }

  function computeERC4626Address(
    ICurveGauge gauge_,
    ICurvePool pool_,
    uint8 coins_
  ) external view returns (ERC4626 vault) {
    
    vault = ERC4626(
      computeCreate2Address(
        keccak256(
          abi.encodePacked(
            // Deployment bytecode:
            type(CurveVault).creationCode,
            // Constructor arguments:
            abi.encode(
              gauge_,
              pool_,
              coins_,
              swapper,
              feesController,
              admin
            )
          )
        )
      )
    );
  }
}
