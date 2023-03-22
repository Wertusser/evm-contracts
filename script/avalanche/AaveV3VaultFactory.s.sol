pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {ERC20} from '../../src/periphery/ERC20.sol';

import {IPool} from '../../src/providers/aaveV3/external/IPool.sol';
import {IRewardsController} from '../../src/providers/aaveV3/external/IRewardsController.sol';
import {AaveV3VaultFactory} from '../../src/providers/aaveV3/AaveV3VaultFactory.sol';

contract DeployScript is Script {
    function deployForAsset(
        string memory name,
        address asset,
        AaveV3VaultFactory deployed
    ) public payable {
        ERC20 want = ERC20(asset);
        deployed.createERC4626(want);
        console2.log(
            name,
            ' - ',
            address(deployed.computeERC4626Address(want))
        );
    }

    function run() public payable returns (AaveV3VaultFactory deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
        IPool lendingPool = IPool(
            vm.envAddress('AVALANCHE_AAVE_V3_LENDING_POOL')
        );
        address rewardRecipient = vm.envAddress(
            'AVALANCHE_AAVE_V3_REWARDS_RECIPIENT'
        );
        IRewardsController rewardsController = IRewardsController(
            vm.envAddress('AVALANCHE_AAVE_V3_REWARDS_CONTROLLER')
        );

        console2.log('broadcaster', vm.addr(deployerPrivateKey));
        vm.startBroadcast(deployerPrivateKey);

        deployed = new AaveV3VaultFactory(
            lendingPool,
            rewardRecipient,
            rewardsController
        );
        // deployed = AaveV3VaultFactory(address(0xA618c7a92243C33E74c9157359D0BDFa66D4e2CD));
        // Investments deploy
        // DAI.e
        deployForAsset(
            'DAI.e',
            address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70),
            deployed
        );
        // FRAX
        deployForAsset(
            'FRAX',
            address(0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64),
            deployed
        );
        // MAI
        deployForAsset(
            'MAI',
            address(0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b),
            deployed
        );
        // USDC
        deployForAsset(
            'USDC',
            address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E),
            deployed
        );
        // USDt
        deployForAsset(
            'USDT',
            address(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7),
            deployed
        );
        // AAVE.e
        deployForAsset(
            'AAVE.e',
            address(0x63a72806098Bd3D9520cC43356dD78afe5D386D9),
            deployed
        );
        // BTC.b
        deployForAsset(
            'BTC.b',
            address(0x152b9d0FdC40C096757F570A51E494bd4b943E50),
            deployed
        );
        // LINK.e
        deployForAsset(
            'LINK.e',
            address(0x5947BB275c521040051D82396192181b413227A3),
            deployed
        );
        // sAVAX
        deployForAsset(
            'sAVAX',
            address(0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE),
            deployed
        );
        // WAVAX
        deployForAsset(
            'WAVAX',
            address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7),
            deployed
        );
        //WBTC.e
        deployForAsset(
            'WBTC.e',
            address(0x50b7545627a5162F82A992c33b87aDc75187B218),
            deployed
        );
        // WETH.e
        deployForAsset(
            'WETH.e',
            address(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB),
            deployed
        );

        vm.stopBroadcast();
    }
}
