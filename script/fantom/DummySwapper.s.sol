pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/interfaces/IERC20.sol";

import {ERC20} from "../../src/periphery/ERC20.sol";
import {DummySwapper} from "../../src/swappers/DummySwapper.sol";
import {StargateVault} from "../../src/providers/stargate/StargateVault.sol";

contract DeployScript is Script {
    function run() public payable returns (DummySwapper deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        console2.log("broadcaster", vm.addr(deployerPrivateKey));
        // deployed = new DummySwapper();

        deployed = DummySwapper(address(0x3e6F0FF767eE5D0e361b00E72b9695fD3f0D217D));
        IERC20 assetFrom = IERC20(address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590));
        IERC20 assetTo = IERC20(address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75));
        assetFrom.approve(address(deployed), 100);
        deployed.swap(assetFrom, assetTo, 100, 0);
        vm.stopBroadcast();
    }
}
