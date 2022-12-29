pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPool} from "../src/providers/aaveV3/external/IPool.sol";
import {IRewardsController} from "../src/providers/aaveV3/external/IRewardsController.sol";
import {AaveV3VaultFactory} from "../src/providers/aaveV3/AaveV3VaultFactory.sol";

contract DeployScript is Script {
    function run() public payable returns (AaveV3VaultFactory deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        IPool lendingPool = IPool(vm.envAddress("AAVE_V3_LENDING_POOL_OPTIMISM"));
        address rewardRecipient = vm.envAddress("AAVE_V3_REWARDS_RECIPIENT_OPTIMISM");
        IRewardsController rewardsController = IRewardsController(vm.envAddress("AAVE_V3_REWARDS_CONTROLLER_OPTIMISM"));


        vm.startBroadcast(deployerPrivateKey);
        
        deployed = new AaveV3VaultFactory(lendingPool, rewardRecipient, rewardsController);
        // deployed = AaveV3VaultFactory(address(0xA618c7a92243C33E74c9157359D0BDFa66D4e2CD));
        // Investments deploy
        // WETH
        deployed.createERC4626(ERC20(address(0x4200000000000000000000000000000000000006)));
        // DAI
        deployed.createERC4626(ERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1)));
        // USDC
        deployed.createERC4626(ERC20(address(0x7F5c764cBc14f9669B88837ca1490cCa17c31607)));
        

        vm.stopBroadcast();
    }
}