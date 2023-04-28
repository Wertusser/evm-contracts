// pragma solidity ^0.8.13;

// import "../ERC4626Compoundable.invariants.t.sol";

// import { PoolMock } from "./mocks/Pool.m.sol";
// import { ERC20Mock, WERC20Mock } from "../mocks/ERC20.m.sol";
// import { IPool } from "../../src/providers/aaveV3/external/IPool.sol";
// import { AaveV3Vault } from "../../src/providers/aaveV3/AaveV3Vault.sol";
// import { RewardsControllerMock } from "./mocks/RewardsController.m.sol";
// import { AaveV3VaultFactory } from "../../src/providers/aaveV3/AaveV3VaultFactory.sol";
// import { IRewardsController } from
//   "../../src/providers/aaveV3/external/IRewardsController.sol";
// import { ISwapper } from "../../src/periphery/Swapper.sol";
// import { FeesController } from "../../src/periphery/FeesController.sol";
// import { SwapperMock } from "../mocks/Swapper.m.sol";

// contract AaveV3VaultInvariants is ERC4626CompoundableInvariants {
//   ERC20Mock public aave;
//   AaveV3Vault public vault;
//   ERC20Mock public underlying;
//   PoolMock public lendingPool;
//   AaveV3VaultFactory public factory;
//   IRewardsController public rewardsController;
//   ISwapper public swapper;
//   FeesController public feesController;

//   function setUp() public {
//     address owner = address(0xBEEFBEEF);

//     aave = new ERC20Mock();
//     underlying = new ERC20Mock();
//     lendingPool = new PoolMock(underlying);
//     rewardsController =
//       new RewardsControllerMock(address(lendingPool.aToken()), address(aave));

//     swapper = new SwapperMock(aave, underlying);
//     feesController = new FeesController(owner);
//     vault = new AaveV3Vault(
//       IERC20(address(underlying)),
//       IERC20(address(lendingPool.aToken())),
//       lendingPool,
//       rewardsController,
//       swapper,
//       feesController,
//       owner
//     );

//     feesController.setFeeBps(address(vault), "harvest", 2500);
//     feesController.setFeeBps(address(vault), "deposit", 2500);
//     feesController.setFeeBps(address(vault), "withdraw", 2500);
//     setVault(IERC4626(address(vault)), IERC20(address(aave)));

//     vm.startPrank(owner);
//     vault.setKeeper(address(0xdeadbeef));
//     vm.stopPrank();

//     excludeContract(address(factory));
//     excludeContract(address(aave));
//     excludeContract(address(lendingPool.aToken()));
//     excludeContract(address(underlying));
//     excludeContract(address(lendingPool));
//     excludeContract(address(rewardsController));
//     excludeContract(address(feesController));
//     excludeContract(address(swapper));
//   }
// }
