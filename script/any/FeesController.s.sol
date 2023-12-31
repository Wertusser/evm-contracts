pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import { ERC20 } from "solmate/tokens/ERC20.sol";
import {FeesController} from '../../src/periphery/FeesController.sol';

contract DeployScript is Script {
    function run() public payable returns (FeesController deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));

        vm.startBroadcast(deployerPrivateKey);
        address broadcaster = vm.addr(deployerPrivateKey);
        console2.log('broadcaster', broadcaster);
        deployed = new FeesController(broadcaster);

        vm.stopBroadcast();
    }
}
