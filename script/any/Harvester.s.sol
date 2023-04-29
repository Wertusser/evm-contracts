pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Harvester } from "../../src/periphery/Harvester.sol";
import { ERC4626Harvest } from "../../src/periphery/ERC4626Harvest.sol";

contract DeployScript is Script {
  IERC20 public USDC = IERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8));

  function run() public payable returns (Harvester deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);
    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);
    // deployed = new Harvester(broadcaster);

    ERC4626Harvest vault =
      ERC4626Harvest(address(0x9dc0d5874e07F9929Dd7A17FdA8B8BBb56Ca2a4e));
    // vault.setKeeper(address(deployed));
    USDC.approve(address(vault), 1e6);
    vault.deposit(1e6, broadcaster);

    vm.stopBroadcast();
  }
}
