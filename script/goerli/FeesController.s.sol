pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {ERC20} from '../../src/periphery/ERC20.sol';

import {FeesController} from '../../src/periphery/FeesController.sol';

contract DeployScript is Script {
    function run() public payable returns (FeesController deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));

        vm.startBroadcast(deployerPrivateKey);

        console2.log('broadcaster', vm.addr(deployerPrivateKey));
        deployed = new FeesController(address(0));
        ///0xeEbbcEbCFD58F1ac20E54EcED2cDeAEa0c27FD1d

        vm.stopBroadcast();
    }
}
