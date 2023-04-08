pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "../../src/periphery/ERC4626.sol";
import { IERC4626Compoundable } from "../../src/periphery/ERC4626Compoundable.sol";
import { ActorBase } from "./Actor.sol";

contract Keeper is ActorBase {
  address public KEEPER = address(0xdeadbeef);
  IERC4626Compoundable public vaultCompoundable;
  IERC20 public reward;

  uint256 public ghost_gainSum;
  uint256 public ghost_zeroGain;

  modifier useKeeper() {
    vm.startPrank(KEEPER);
    _;
    vm.stopPrank();
  }

  constructor(IERC4626Compoundable _vault, IERC20 reward_)
    ActorBase(IERC4626(address(_vault)))
  {
    vaultCompoundable = _vault;
    reward = reward_;
  }

  // helper methods for actors

  function callHarvestSummary() public virtual {
    console.log("\nKeeper summary:");
    console.log("-------------------");
    console.log("total gain", ghost_gainSum);
    console.log("zero transfer", ghost_zeroGain);
    console.log("\nCall summary:");
    console.log("-------------------");
    console.log("harvest", calls["harvest"]);
    console.log("tend", calls["tend"]);
  }

  // Core ERC4262Compoundable methods

  function harvest(uint256 expectedOut) public useKeeper() countCall("harvest") {
    vm.prank(KEEPER);
    ghost_gainSum += vaultCompoundable.harvest(reward, expectedOut);
  }

  function tend() public useKeeper() countCall("tend") {
    vm.prank(KEEPER);
    vaultCompoundable.tend();
  }
}
