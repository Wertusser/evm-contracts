// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";

// import { ERC20 } from "../../src/periphery/ERC20.sol";

// import "forge-std/interfaces/IERC20.sol";
// import "../../src/providers/stargate/external/IStargateLPStaking.sol";
// import "../../src/providers/stargate/external/IStargateRouter.sol";
// import "../../src/providers/stargate/external/IStargatePool.sol";
// import "../../src/providers/stargate/external/IStargateFactory.sol";
// import "../../src/periphery/FeesController.sol";
// import { ISwapper } from "../../src/periphery/Swapper.sol";
// import { StargateVaultFactory } from
//   "../../src/providers/stargate/StargateVaultFactory.sol";
// import { StargateVault } from "../../src/providers/stargate/StargateVault.sol";
// import { StargateLPStakingMock } from "../../test/stargate/mocks/LPStaking.m.sol";
// import { ERC20Mock } from "../../test/mocks/ERC20.m.sol";

// contract DeployScript is Script {
//   IERC20 public DAI = IERC20(address(0xBa8DCeD3512925e52FE67b1b5329187589072A55));
//   IERC20 public USDC = IERC20(address(0xDf0360Ad8C5ccf25095Aa97ee5F2785c8d848620));
//   address public ADMIN = address(0x777BcC85d91EcE0C641a6F03F35a2A98F4049777);

//   function deployForPool(
//     string memory name,
//     uint256 poolId,
//     uint256 stakingId
//   ) public payable returns (address vault) {
//     deployed.createERC4626_(poolId, stakingId);
//     vault = new StargateVault(
//           IERC20(address(underlying)),
//           IStargatePool(address(0x7612aE2a34E5A363E137De748801FB4c86499152)),
//           IStargateRouter(address(0x7612aE2a34E5A363E137De748801FB4c86499152)),
//           IStargateLPStaking(address(0x0)),
//           0,
//           FeesController(address(0xeEbbcEbCFD58F1ac20E54EcED2cDeAEa0c27FD1d)),
//           ISwapper(address(0xD3cBfffBc32A6a2CBD35C8fAB9cA518936713Bc5)),
//           owner
//         );

//     // USDC.approve(vault, 10 ** 6);
//     // require(StargateVault(vault).owner() == ADMIN);
//     // console2.log("USDC balance", USDC.balanceOf(ADMIN));
//     // uint256 shares = StargateVault(vault).deposit(10 ** 6, ADMIN);
//     // IERC20(vault).approve(vault, shares / 10);
//     // StargateVault(vault).withdraw(shares / 10, ADMIN, ADMIN);
//     console2.log(name, "-", vault);
//   }

//   function run() public payable returns (StargateVaultFactory deployed) {
//     uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

//     vm.startBroadcast(deployerPrivateKey);
//     address broadcaster = vm.addr(deployerPrivateKey);
//     console2.log("broadcaster", broadcaster);

//     deployed = new StargateVaultFactory(
//           IStargateFactory(address(0xB30300c11FF54f8F674a9AA0777D8D5e9fefd652)),
//           IStargateRouter(address(0x7612aE2a34E5A363E137De748801FB4c86499152)),
//           stakingMock,
//           FeesController(address(0xeEbbcEbCFD58F1ac20E54EcED2cDeAEa0c27FD1d)),
//           ISwapper(address(0xD3cBfffBc32A6a2CBD35C8fAB9cA518936713Bc5)),
//           ADMIN
//         );

//     // deployed = StargateVaultFactory(address());
//     // Investments deploy

//     deployForPool("USDC", 1, 0, DAI, deployed);

//     vm.stopBroadcast();
//   }
// }
