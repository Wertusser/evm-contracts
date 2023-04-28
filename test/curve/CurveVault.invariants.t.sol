// pragma solidity ^0.8.13;

// import "../ERC4626Compoundable.invariants.t.sol";
// import { ERC20Mock } from "../mocks/ERC20.m.sol";
// import { SwapperMock } from "../mocks/Swapper.m.sol";
// import { CurveVault } from "../../src/providers/curve/CurveVault.sol";
// import { ISwapper } from "../../src/periphery/Swapper.sol";
// import { FeesController } from "../../src/periphery/FeesController.sol";
// import { CurvePoolMock, ICurvePool } from "./mocks/CurvePool.m.sol";
// import { CurveGaugeMock } from "./mocks/CurveGauge.m.sol";

// contract CurveVaultInvariants is ERC4626CompoundableInvariants {
//   address public owner;
//   ERC20Mock public underlying;
//   ERC20Mock public underlying2;
//   ERC20Mock public reward;
//   CurvePoolMock public pool;
//   CurveGaugeMock public gauge;
//   ISwapper public swapper;
//   FeesController public feesController;
//   CurveVault public vault;

//   function setUp() public {
//     owner = msg.sender;
//     reward = new ERC20Mock();
//     underlying = new ERC20Mock();
//     underlying2 = new ERC20Mock();
//     pool = new CurvePoolMock(underlying, underlying2);
//     gauge = new CurveGaugeMock(reward, pool.lpToken());

//     swapper = new SwapperMock(reward, underlying);
//     feesController = new FeesController(address(0xdeaddead));

//     vault = new CurveVault(
//         gauge,
//         ICurvePool(address(pool)),
//         2,
//         swapper,
//         feesController,
//         owner
//     );

//     setVault(IERC4626(address(vault)), IERC20(address(reward)));

//     vm.startPrank(owner);
//     vault.setKeeper(address(0xdeadbeef));
//     vm.stopPrank();

//     excludeContract(address(underlying));
//     excludeContract(address(underlying2));
//     excludeContract(address(pool.lpToken()));
//     excludeContract(address(reward));
//     excludeContract(address(pool));
//     excludeContract(address(gauge));
//     excludeContract(address(feesController));
//     excludeContract(address(swapper));
//   }
// }
