// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol";

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
import {SwapperMock} from "../mocks/Swapper.m.sol";

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
    aave = new ERC20Mock();
    underlying = new ERC20Mock();
    aToken = new WERC20Mock(underlying);
    lendingPool = new PoolMock(underlying);
    rewardsController = new RewardsControllerMock(address(aave));

    swapper = new SwapperMock(aave, underlying);
    feesController = new FeesController(msg.sender);


    vault = new AaveV3Vault(
      underlying,
      aToken,
      lendingPool,
      rewardsController,
      swapper,
      feesController,
      msg.sender
    );

    // for ERC4626Test setup
    _underlying_ = address(underlying);
    _vault_ = address(vault);
    _delta_ = 0;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = true;
  }

  // custom setup for yield
  function setUpYield(Init memory init) public override {
    // setup initial yield
    if (init.yield >= 0) {
      uint256 gain = uint256(init.yield);
      try underlying.mint(address(lendingPool), gain) { }
      catch {
        vm.assume(false);
      }
      try aToken.mint(address(vault), gain) { }
      catch {
        vm.assume(false);
      }
    } else {
      vm.assume(false); // TODO: test negative yield scenario
    }
  }
}
