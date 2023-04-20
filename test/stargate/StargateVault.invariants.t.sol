pragma solidity ^0.8.13;

import "../ERC4626Compoundable.invariants.t.sol";

import { IERC20 as IIERC20 } from "forge-std/interfaces/IERC20.sol";

import { ERC20Mock } from "../mocks/ERC20.m.sol";
import { SwapperMock } from "../mocks/Swapper.m.sol";
import { StargateVault } from "../../src/providers/stargate/StargateVault.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { FeesController } from "../../src/periphery/FeesController.sol";
import { StargatePoolMock } from "./mocks/Pool.m.sol";
import { StargateRouterMock } from "./mocks/Router.m.sol";
import { StargateLPStakingMock } from "./mocks/LPStaking.m.sol";

contract StargateVaultInvariants is ERC4626CompoundableInvariants {
  address public owner;
  ERC20Mock public underlying;
  ERC20Mock public reward;
  StargatePoolMock public poolMock;
  StargateRouterMock public routerMock;
  StargateLPStakingMock public stakingMock;
  ISwapper public swapper;
  FeesController public feesController;
  StargateVault public vault;

  function setUp() public {
    owner = msg.sender;

    underlying = new ERC20Mock();
    reward = new ERC20Mock();

    poolMock = new StargatePoolMock(0, underlying);
    routerMock = new StargateRouterMock(poolMock);
    stakingMock =
      new StargateLPStakingMock(ERC20Mock(address(poolMock.lpToken())), reward);

    swapper = new SwapperMock(reward, underlying);
    feesController = new FeesController(owner);

    vault = new StargateVault(
          IIERC20(address(underlying)),
          poolMock,
          routerMock,
          stakingMock,
          0,
          swapper,
          feesController,
          owner
        );
    feesController.setFeeBps(address(vault), "harvest", 2500);
    feesController.setFeeBps(address(vault), "deposit", 2500);
    feesController.setFeeBps(address(vault), "withdraw", 2500);
    setVault(IERC4626(address(vault)), IERC20(address(reward)));

    vm.startPrank(owner);
    vault.setKeeper(address(0xdeadbeef));
    vm.stopPrank();

    excludeContract(address(underlying));
    excludeContract(address(reward));
    excludeContract(address(poolMock));
    excludeContract(address(poolMock.lpToken()));
    excludeContract(address(feesController));
    excludeContract(address(routerMock));
    excludeContract(address(stakingMock));
    excludeContract(address(feesController));
    excludeContract(address(swapper));
  }
}
