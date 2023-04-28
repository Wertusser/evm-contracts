// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC4626Test } from "erc4626-tests/ERC4626.test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { PoolMock } from "./mocks/Pool.m.sol";
import { ERC20Mock, WERC20Mock } from "../mocks/ERC20.m.sol";
import { IPool } from "../../src/providers/aaveV3/external/IPool.sol";
import { AaveV3Vault } from "../../src/providers/aaveV3/AaveV3Vault.sol";
import { RewardsControllerMock } from "./mocks/RewardsController.m.sol";
import { AaveV3VaultFactory } from "../../src/providers/aaveV3/AaveV3VaultFactory.sol";
import { IRewardsController } from
  "../../src/providers/aaveV3/external/IRewardsController.sol";

import { ISwapper } from "../../src/periphery/Swapper.sol";
import { FeesController } from "../../src/periphery/FeesController.sol";
import { SwapperMock } from "../mocks/Swapper.m.sol";

contract AaveV3VaultStdTest is ERC4626Test {
  address public constant rewardRecipient = address(0x01);

  ERC20Mock public aave;
  WERC20Mock public aToken;
  AaveV3Vault public vault;
  ERC20Mock public underlying;
  PoolMock public lendingPool;
  AaveV3VaultFactory public factory;
  IRewardsController public rewardsController;
  ISwapper public swapper;
  FeesController public feesController;

  function setUp() public override {
    address treasury = address(0xDEADDEAD);
    address owner = address(0xBEEFBEEF);

    aave = new ERC20Mock();
    underlying = new ERC20Mock();
    lendingPool = new PoolMock(underlying);
    rewardsController =
      new RewardsControllerMock(address(lendingPool.aToken()), address(aave));

    swapper = new SwapperMock(aave, underlying);
    feesController = new FeesController(treasury);

    vault = new AaveV3Vault(
      IERC20(address(underlying)),
      IERC20(address(lendingPool.aToken())),
      lendingPool,
      rewardsController,
      swapper,
      feesController,
      owner
    );

    vm.startPrank(owner);
    // vault.setKeeper(address(0xdeadbeef));
    vm.stopPrank();

    // for ERC4626Test setup
    _underlying_ = address(underlying);
    _vault_ = address(vault);
    _delta_ = 0;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = true;
  }
}
