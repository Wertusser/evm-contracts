// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ERC4626Test } from "erc4626-tests/ERC4626.test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { CurvePoolMock } from "./mocks/CurvePool.m.sol";
import { CurveGaugeMock } from "./mocks/CurveGauge.m.sol";
import { ERC20Mock } from "../mocks/ERC20.m.sol";
import { CurveVault } from "../../src/providers/curve/CurveVault.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { FeesController } from "../../src/periphery/FeesController.sol";
import { SwapperMock } from "../mocks/Swapper.m.sol";

contract CurveVaultStdTest is ERC4626Test {
  ERC20Mock public reward;
  ERC20Mock public underlying;
  CurveVault public vault;
  CurvePoolMock public pool;
  CurveGaugeMock public gauge;
  ISwapper public swapper;
  FeesController public feesController;

  function setUp() public override {
    reward = new ERC20Mock();
    underlying = new ERC20Mock();
    pool = new CurvePoolMock(underlying, new ERC20Mock());
    gauge = new CurveGaugeMock(reward, pool.lpToken());

    swapper = new SwapperMock(reward, underlying);
    feesController = new FeesController(msg.sender);

    vault = new CurveVault(
        gauge,
        pool,
        2,
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
  }
}
