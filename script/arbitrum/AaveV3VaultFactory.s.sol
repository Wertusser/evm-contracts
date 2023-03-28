// pragma solidity ^0.8.13;

// import 'forge-std/Script.sol';
// import 'forge-std/console2.sol';

// import {ERC20} from '../../src/periphery/ERC20.sol';

// import {IPool} from '../../src/providers/aaveV3/external/IPool.sol';
// import {IRewardsController} from '../../src/providers/aaveV3/external/IRewardsController.sol';
// import {AaveV3VaultFactory} from '../../src/providers/aaveV3/AaveV3VaultFactory.sol';

// contract DeployScript is Script {
//     function deployForAsset(
//         string memory name,
//         address asset,
//         AaveV3VaultFactory deployed
//     ) public payable {
//         ERC20 want = ERC20(asset);
//         deployed.createERC4626(want);
//         console2.log(name, ' - ', address(deployed.computeERC4626Address(want)));
//     }

//     function run() public payable returns (AaveV3VaultFactory deployed) {
//         uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
//         IPool lendingPool = IPool(
//             vm.envAddress('ARBITRUM_AAVE_V3_LENDING_POOL')
//         );
//         address rewardRecipient = vm.envAddress(
//             'ARBITRUM_AAVE_V3_REWARDS_RECIPIENT'
//         );
//         IRewardsController rewardsController = IRewardsController(
//             vm.envAddress('ARBITRUM_AAVE_V3_REWARDS_CONTROLLER')
//         );

//         console2.log('broadcaster', vm.addr(deployerPrivateKey));
//         vm.startBroadcast(deployerPrivateKey);

//         // deployed = new AaveV3VaultFactory(
//         //     lendingPool,
//         //     rewardRecipient,
//         //     rewardsController
//         // );
//         deployed = AaveV3VaultFactory(
//             address(0x8eaE291df7aDe0B868d4495673FC595483a9Cc24)
//         );
//         // Investments deploy

//         // DAI
//         deployForAsset(
//             'DAI',
//             address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1),
//             deployed
//         );

//         // EURS
//         deployForAsset(
//             'EURS',
//             address(0xD22a58f79e9481D1a88e00c343885A588b34b68B),
//             deployed
//         );

//         // USDC
//         deployForAsset(
//             'USDC',
//             address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8),
//             deployed
//         );

//         // USDT
//         deployForAsset(
//             'USDT',
//             address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9),
//             deployed
//         );

//         // AAVE
//         deployForAsset(
//             'AAVE',
//             address(0xba5DdD1f9d7F570dc94a51479a000E3BCE967196),
//             deployed
//         );

//         // LINK
//         deployForAsset(
//             'LINK',
//             address(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4),
//             deployed
//         );

//         // WBTC
//         deployForAsset(
//             'WBTC',
//             address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f),
//             deployed
//         );

//         // WETH
//         deployForAsset(
//             'WETH',
//             address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1),
//             deployed
//         );
//         vm.stopBroadcast();
//     }
// }
