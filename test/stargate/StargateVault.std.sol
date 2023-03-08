// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc4626-tests/ERC4626.test.sol";
import {IERC20 as IIERC20} from "forge-std/interfaces/IERC20.sol";

import {ERC20Mock} from "../mocks/ERC20.m.sol";
import {StargateVault} from "../../src/providers/stargate/StargateVault.sol";
import {ISwapper} from "../../src/Swapper.sol";
import {DummySwapper} from "../../src/swappers/DummySwapper.sol";
import {StargatePoolMock} from "./mocks/Pool.m.sol";
import {StargateRouterMock} from "./mocks/Router.m.sol";
import {StargateLPStakingMock} from "./mocks/LPStaking.m.sol";

contract StargateVaultStdTest is ERC4626Test {

    ERC20Mock public lpToken;
    ERC20Mock public underlying;
    ERC20Mock public reward;

    StargatePoolMock public poolMock;
    StargateRouterMock public routerMock;
    StargateLPStakingMock public stakingMock;

    ISwapper public swapper;

    StargateVault public vault;

    function setUp() public override {
        lpToken = new ERC20Mock();
        underlying = new ERC20Mock();
        reward = new ERC20Mock();

        poolMock = new StargatePoolMock(0, underlying, lpToken);
        routerMock = new StargateRouterMock(poolMock);
        stakingMock = new StargateLPStakingMock(lpToken, reward);

        swapper = new DummySwapper();

        vault = new StargateVault(
          IIERC20(address(underlying)),
          poolMock,
          routerMock,
          stakingMock,
          0,
          IIERC20(address(lpToken)),
          IIERC20(address(reward)),
          swapper
        );
        vault.setKeeper(address(0xFF));

        _underlying_ = address(underlying);
        _vault_ = address(vault);
        _delta_ = 0;
        _vaultMayBeEmpty = false;
        _unlimitedAmount = true;
    }


    function testFail_harvestNotKeeper(address caller) public {
      vm.prank(caller);
      uint amountOut = vault.harvest();
    }

    function testFail_tendNotKeeper(address caller) public {
      vm.prank(caller);
      uint amountOut = vault.tend();
    }


    function test_harvest() public {
      vm.prank(address(0xFF));

      uint expected = vault.previewHarvest();
      uint amountOut = vault.harvest();
      assertEq(amountOut, expected);
    }

    function test_tend() public {
      vm.prank(address(0xFF));

      uint expected = vault.previewTend();
      uint amountOut = vault.tend();
      assertEq(amountOut, expected);
    }
} 
