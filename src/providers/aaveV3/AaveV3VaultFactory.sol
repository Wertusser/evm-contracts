// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { ERC20, IERC20 } from "../../periphery/ERC20.sol";
import { ERC4626 } from "../../periphery/ERC4626.sol";

import { IPool } from "./external/IPool.sol";
import { AaveV3Vault } from "./AaveV3Vault.sol";
import { ERC4626Factory } from "../../periphery/ERC4626Factory.sol";
import { IRewardsController } from "./external/IRewardsController.sol";
import "../../periphery/FeesController.sol";
import "../../periphery/Swapper.sol";

/// @title AaveV3VaultFactory
/// @notice Factory for creating AaveV3Vault contracts
contract AaveV3VaultFactory is ERC4626Factory {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------

  /// @notice Thrown when trying to deploy an AaveV3Vault vault using an asset without an aToken
  error AaveV3VaultFactory__ATokenNonexistent();
  error AaveV3VaultFactory__Deprecated();

  /// -----------------------------------------------------------------------
  /// Immutable params
  /// -----------------------------------------------------------------------

  ERC20 public immutable reward;
  /// @notice The Aave Pool contract
  IPool public immutable lendingPool;

  /// @notice The Aave RewardsController contract
  IRewardsController public immutable rewardsController;

  /// @notice Swapper contract
  ISwapper public immutable swapper;
  /// @notice fees controller
  FeesController public immutable feesController;

  address public admin;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    ERC20 reward_,
    IPool lendingPool_,
    IRewardsController rewardsController_,
    ISwapper swapper_,
    FeesController feesController_
  ) {
    reward = reward_;
    lendingPool = lendingPool_;
    rewardsController = rewardsController_;
    swapper = swapper_;
    feesController = feesController_;
    admin = msg.sender;
  }

  /// -----------------------------------------------------------------------
  /// External functions
  /// -----------------------------------------------------------------------

  function createERC4626(ERC20 asset) external virtual override returns (ERC4626 vault) {
    IPool.ReserveData memory reserveData = lendingPool.getReserveData(address(asset));
    address aTokenAddress = reserveData.aTokenAddress;
    if (aTokenAddress == address(0)) {
      revert AaveV3VaultFactory__ATokenNonexistent();
    }

    vault = new AaveV3Vault{salt: bytes32(0)}(
      asset,
      ERC20(aTokenAddress),
      lendingPool,
      rewardsController,
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
    override
    returns (ERC4626 vault)
  {
    IPool.ReserveData memory reserveData = lendingPool.getReserveData(address(asset));
    address aTokenAddress = reserveData.aTokenAddress;

    vault = ERC4626(
      _computeCreate2Address(
        keccak256(
          abi.encodePacked(
            // Deployment bytecode:
            type(AaveV3Vault).creationCode,
            // Constructor arguments:
            abi.encode(
              asset,
              ERC20(aTokenAddress),
              lendingPool,
              rewardsController,
              swapper,
              address(feesController),
              admin
            )
          )
        )
      )
    );
  }
}
