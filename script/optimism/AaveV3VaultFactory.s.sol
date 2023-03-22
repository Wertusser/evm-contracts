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
            vm.envAddress('OPTIMISM_AAVE_V3_LENDING_POOL')
        );
        address rewardRecipient = vm.envAddress(
            'OPTIMISM_AAVE_V3_REWARDS_RECIPIENT'
        );
        IRewardsController rewardsController = IRewardsController(
            vm.envAddress('OPTIMISM_AAVE_V3_REWARDS_CONTROLLER')
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

        // WETH
        deployed.createERC4626(
            ERC20(address(0x4200000000000000000000000000000000000006))
        );

        // DAI
        deployed.createERC4626(
            ERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1))
        );

        // USDC
        deployed.createERC4626(
            ERC20(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607))
        );

        // Synth sUSD
        deployed.createERC4626(
            ERC20(address(0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9))
        );

        // USDT
        deployed.createERC4626(
            ERC20(address(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))
        );

        // AAVE
        deployed.createERC4626(
            ERC20(address(0x76FB31fb4af56892A25e32cFC43De717950c9278))
        );

        //LINK
        deployed.createERC4626(
            ERC20(address(0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6))
        );

        // WBTC
        deployed.createERC4626(
            ERC20(address(0x68f180fcCe6836688e9084f035309E29Bf0A2095))
        );

        vm.stopBroadcast();
    }
}
