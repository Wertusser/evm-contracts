// pragma solidity ^0.8.13;

// import 'forge-std/Script.sol';

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
//         console2.log(
//             name,
//             ' - ',
//             address(deployed.computeERC4626Address(want))
//         );
//     }

//     function run() public payable returns (AaveV3VaultFactory deployed) {
//         uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
//         IPool lendingPool = IPool(
//             vm.envAddress('POLYGON_AAVE_V3_LENDING_POOL')
//         );
//         address rewardRecipient = vm.envAddress(
//             'POLYGON_AAVE_V3_REWARDS_RECIPIENT'
//         );
//         IRewardsController rewardsController = IRewardsController(
//             vm.envAddress('POLYGON_AAVE_V3_REWARDS_CONTROLLER')
//         );

//         console2.log('broadcaster', vm.addr(deployerPrivateKey));
//         vm.startBroadcast(deployerPrivateKey);

//         // deployed = new AaveV3VaultFactory(
//         //     lendingPool,
//         //     rewardRecipient,
//         //     rewardsController
//         // );
//         deployed = AaveV3VaultFactory(address(0x8eaE291df7aDe0B868d4495673FC595483a9Cc24));
//         // Investments deploy
//         // agEUR
//         deployForAsset(
//             'agEUR',
//             address(0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4),
//             deployed
//         );

//         // DAI

//         deployForAsset(
//             'DAI',
//             address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063),
//             deployed
//         );

//         // EURS
//         deployForAsset(
//             'EURS',
//             address(0xE111178A87A3BFf0c8d18DECBa5798827539Ae99),
//             deployed
//         );

//         // jEUR
//         deployForAsset(
//             'jEUR',
//             address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c),
//             deployed
//         );

//         // miMAI
//         deployForAsset(
//             'miMAI',
//             address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
//             deployed
//         );

//         // USDC
//         deployForAsset(
//             'USDC',
//             address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174),
//             deployed
//         );

//         // USDT
//         deployForAsset(
//             'USDT',
//             address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F),
//             deployed
//         );

//         // AAVE
//         deployForAsset(
//             'AAVE',
//             address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B),
//             deployed
//         );

//         // BAL
//         deployForAsset(
//             'BAL',
//             address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3),
//             deployed
//         );

//         // DPI
//         deployForAsset(
//             'DPI',
//             address(0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369),
//             deployed
//         );

//         // GHST
//         // deployed.createERC4626(
//         //     ERC20(address(0x385eeac5cb85a38a9a07a70c73e0a3271cfb54a7))
//         // );

//         // LINK
//         deployForAsset(
//             'LINK',
//             address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39),
//             deployed
//         );

//         // MaticX
//         // deployed.createERC4626(
//         //     ERC20(address(0xfa68fb4628dff1028cfec22b4162fccd0d45efb6))
//         // );

//         // stMATIC
//         deployForAsset(
//             'stMATIC',
//             address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4),
//             deployed
//         );

//         // SUSHI
//         deployForAsset(
//             'SUSHI',
//             address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a),
//             deployed
//         );

//         // WBTC
//         deployForAsset(
//             'WBTC',
//             address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6),
//             deployed
//         );

//         // WETH
//         deployForAsset(
//             'WETH',
//             address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619),
//             deployed
//         );

//         // WMATIC
//         deployForAsset(
//             'WMATIC',
//             address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270),
//             deployed
//         );

//         vm.stopBroadcast();
//     }
// }
