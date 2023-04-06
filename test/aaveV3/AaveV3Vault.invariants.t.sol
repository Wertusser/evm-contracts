pragma solidity ^0.8.13;

import "../ERC4626Compoundable.invariants.t.sol";

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

contract AaveV3VaultInvariants is ERC4626CompoundableInvariants {
  ERC20Mock public aave;
  WERC20Mock public aToken;
  AaveV3Vault public vault;
  ERC20Mock public underlying;
  PoolMock public lendingPool;
  AaveV3VaultFactory public factory;
  IRewardsController public rewardsController;
  ISwapper public swapper;
  FeesController public feesController;

  function setUp() public {
    aave = new ERC20Mock();
    underlying = new ERC20Mock();
    aToken = new WERC20Mock(underlying);
    lendingPool = new PoolMock();
    rewardsController = new RewardsControllerMock(address(aave));
    
    swapper = new SwapperMock(aave, underlying);
    feesController = new FeesController();

    factory = new AaveV3VaultFactory(
            aave,
            lendingPool,
            rewardsController,
            swapper,
            feesController
        );

    lendingPool.setReserveAToken(address(underlying), aToken);
    underlying.mint(address(lendingPool), 10 ** 24);

    vault = AaveV3Vault(address(factory.createERC4626(underlying)));
    setVault(vault, aave);

    excludeContract(address(factory));
    excludeContract(address(aave));
    excludeContract(address(aToken));
    excludeContract(address(underlying));
    excludeContract(address(lendingPool));
    excludeContract(address(rewardsController));
    excludeContract(address(feesController));
    excludeContract(address(swapper));
  }
}
