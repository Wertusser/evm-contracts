// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc4626-tests/ERC4626.test.sol";
import { IERC20 as IIERC20 } from "forge-std/interfaces/IERC20.sol";

import { ERC20Mock } from "../mocks/ERC20.m.sol";
import { SwapperMock } from "../mocks/Swapper.m.sol";
import {
  StargateVault, IStargatePool
} from "../../src/providers/stargate/StargateVault.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { FeesController } from "../../src/periphery/FeesController.sol";
import { StargatePoolMock } from "./mocks/Pool.m.sol";
import { StargateRouterMock } from "./mocks/Router.m.sol";
import { StargateLPStakingMock } from "./mocks/LPStaking.m.sol";

contract StargateVaultStdTest is ERC4626Test {
  ERC20Mock public lpToken;
  ERC20Mock public underlying;
  ERC20Mock public reward;

  StargatePoolMock public poolMock;
  StargateRouterMock public routerMock;
  StargateLPStakingMock public stakingMock;

  ISwapper public swapper;
  FeesController public feesController;

  StargateVault public vault;

  address public owner;

  function setUp() public override {
    owner = msg.sender;

    underlying = new ERC20Mock();
    reward = new ERC20Mock();

    poolMock = new StargatePoolMock(0, underlying);
    routerMock = new StargateRouterMock(poolMock);
    stakingMock = new StargateLPStakingMock(lpToken, reward);

    swapper = new SwapperMock(reward, underlying);
    feesController = new FeesController(owner);

    vault = new StargateVault(
          IIERC20(address(underlying)),
          IStargatePool(address(poolMock)),
          routerMock,
          stakingMock,
          0,
          swapper,
          feesController,
          owner
        );

    _underlying_ = address(poolMock);
    _vault_ = address(vault);
    _delta_ = 1;
    _vaultMayBeEmpty = false;
    _unlimitedAmount = false;
  }
}
