pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import {ERC20} from 'solmate/tokens/ERC20.sol';
import {DummySwapper} from '../../src/swappers/DummySwapper.sol';

contract DeployScript is Script {
    function run() public payable returns (DummySwapper deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));

        vm.startBroadcast(deployerPrivateKey);

        console2.log('broadcaster', vm.addr(deployerPrivateKey));
        deployed = new DummySwapper();
        ///0xD3cBfffBc32A6a2CBD35C8fAB9cA518936713Bc5

        vm.stopBroadcast();
    }
}
