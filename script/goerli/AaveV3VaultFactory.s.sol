// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";
// import "forge-std/console2.sol";

// import {ERC20} from '../../src/periphery/ERC20.sol';

// import {IPool} from "../../src/providers/aaveV3/external/IPool.sol";
// import {IRewardsController} from "../../src/providers/aaveV3/external/IRewardsController.sol";
// import {AaveV3VaultFactory} from "../../src/providers/aaveV3/AaveV3VaultFactory.sol";
// import {AaveV3Vault} from "../../src/providers/aaveV3/AaveV3Vault.sol";

// contract DeployScript is Script {
//     function deployForAsset(string memory name, address asset, AaveV3VaultFactory deployed) public payable {
//         ERC20 want = ERC20(asset);
//         deployed.createERC4626(want);
//         address vault = address(deployed.computeERC4626Address(want));

//         // ERC20(asset).approve(vault, 10 ** 6);
//         // uint256 shares = AaveV3Vault(vault).deposit(10 ** 6, msg.sender);
//         // ERC20(vault).approve(vault, shares / 10);
//         // AaveV3Vault(vault).withdraw(shares / 10, msg.sender, msg.sender);
//         console2.log(name, "-", vault);
//     }

//     function run() public payable returns (AaveV3VaultFactory deployed) {
//         uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
//         IPool lendingPool = IPool(address(0x7b5C526B7F8dfdff278b4a3e045083FBA4028790));
//         address rewardRecipient = vm.addr(deployerPrivateKey);
//         IRewardsController rewardsController = IRewardsController(address(0x12Ff6eba0767076B056cD722aC8817D771bbCB97));

//         console2.log("broadcaster", vm.addr(deployerPrivateKey));
//         vm.startBroadcast(deployerPrivateKey);

//         // deployed = new AaveV3VaultFactory(
//         //     lendingPool,
//         //     rewardRecipient,
//         //     rewardsController
//         // );
//         deployed = AaveV3VaultFactory(address(0x9D2AcB1D33eb6936650Dafd6e56c9B2ab0Dd680c));
//         // Investments deploy

//         // // DAI
//         // deployForAsset("DAI", address(0xBa8DCeD3512925e52FE67b1b5329187589072A55), deployed);

//         // // EURS
//         // deployForAsset("EURS", address(0xBC33cfbD55EA6e5B97C6da26F11160ae82216E2b), deployed);

//         // // USDC
//         // deployForAsset("USDC", address(0x65aFADD39029741B3b8f0756952C74678c9cEC93), deployed);

//         // // USDT
//         // deployForAsset("USDT", address(0x2E8D98fd126a32362F2Bd8aA427E59a1ec63F780), deployed);

//         // // AAVE
//         // deployForAsset("AAVE", address(0x8153A21dFeB1F67024aA6C6e611432900FF3dcb9), deployed);

//         // // LINK
//         // deployForAsset("LINK", address(0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29), deployed);

//         // // WBTC
//         // deployForAsset("WBTC", address(0x45AC379F019E48ca5dAC02E54F406F99F5088099), deployed);

//         // WETH
//         // deployForAsset("WETH", address(0xCCB14936C2E000ED8393A571D15A2672537838Ad), deployed);
//         vm.stopBroadcast();
//     }
// }
