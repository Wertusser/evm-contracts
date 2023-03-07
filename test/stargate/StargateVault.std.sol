// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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

    // copied from StargateVault.t.sol
    ERC20Mock public lpToken;
    ERC20Mock public underlying;
    ERC20Mock public reward;

    StargatePoolMock public poolMock;
    StargateRouterMock public routerMock;
    StargateLPStakingMock public stakingMock;

    ISwapper public swapper;

    StargateVault public vault;

    function setUp() public override {
        // copied from StargateVault.t.sol
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

        // for ERC4626Test setup
        _underlying_ = address(underlying);
        _vault_ = address(vault);
        _delta_ = 0;
        _vaultMayBeEmpty = false;
        _unlimitedAmount = true;
    }

    // custom setup for yield
    function setUpYield(Init memory init) public override {}
}
