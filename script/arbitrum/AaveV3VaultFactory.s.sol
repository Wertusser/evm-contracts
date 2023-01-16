pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {IPool} from '../../src/providers/aaveV3/external/IPool.sol';
import {IRewardsController} from '../../src/providers/aaveV3/external/IRewardsController.sol';
import {AaveV3VaultFactory} from '../../src/providers/aaveV3/AaveV3VaultFactory.sol';

contract DeployScript is Script {
    function run() public payable returns (AaveV3VaultFactory deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
        IPool lendingPool = IPool(
            vm.envAddress('ARBITRUM_AAVE_V3_LENDING_POOL')
        );
        address rewardRecipient = vm.envAddress(
            'ARBITRUM_AAVE_V3_REWARDS_RECIPIENT'
        );
        IRewardsController rewardsController = IRewardsController(
            vm.envAddress('ARBITRUM_AAVE_V3_REWARDS_CONTROLLER')
        );

        vm.startBroadcast(deployerPrivateKey);

        deployed = new AaveV3VaultFactory(
            lendingPool,
            rewardRecipient,
            rewardsController
        );
        // deployed = AaveV3VaultFactory(address(0xA618c7a92243C33E74c9157359D0BDFa66D4e2CD));
        // Investments deploy

        // // DAI
        // deployed.createERC4626(
        //     ERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1))
        // );

        // // EURS
        // deployed.createERC4626(
        //     ERC20(address(0xD22a58f79e9481D1a88e00c343885A588b34b68B))
        // );

        // // USDC
        // deployed.createERC4626(
        //     ERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8))
        // );

        // // USDT
        // deployed.createERC4626(
        //     ERC20(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9))
        // );

        // // AAVE
        // deployed.createERC4626(
        //     ERC20(address(0xba5DdD1f9d7F570dc94a51479a000E3BCE967196))
        // );

        // // LINK
        // deployed.createERC4626(
        //     ERC20(address(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4))
        // );

        // // WBTC
        // deployed.createERC4626(
        //     ERC20(address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f))
        // );

        // // WETH
        // deployed.createERC4626(
        //     ERC20(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1))
        // );

        vm.stopBroadcast();
    }
}
