pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

import {
  ERC4626Compoundable,
  IERC4626Compoundable
} from "../../src/periphery/ERC4626Compoundable.sol";
import { ActorBase } from "./Actor.sol";

contract Keeper is ActorBase {
  address public KEEPER = address(0xdeadbeef);
  ERC4626Compoundable public vaultCompoundable;
  IERC20 public reward;

  uint256 public ghost_gainSum;
  uint256 public ghost_zeroGain;

  modifier useKeeper() {
    currentActor = KEEPER;

    timestamp = block.timestamp + 1;
    vm.warp(timestamp);

    vm.startPrank(currentActor);
    _;
    vm.stopPrank();
  }

  constructor(IERC4626Compoundable _vault, IERC20 reward_)
    ActorBase(IERC4626(address(_vault)))
  {
    vaultCompoundable = ERC4626Compoundable(address(_vault));
    reward = reward_;
  }

  // helper methods for actors

  function callHarvestSummary() public virtual {
    console.log("\nKeeper summary:");
    console.log("-------------------");
    console.log("total liquidity", vaultCompoundable.totalLiquidity());
    console.log("total gain (vault)", vaultCompoundable.totalGain());
    console.log("total gain (ghost)", ghost_gainSum);
    console.log("zero harvest", ghost_zeroGain);
    console.log("harvest/tend", calls["harvestTend"]);
  }

  // Core ERC4262Compoundable methods

  function harvestTendSync(uint256 expectedOut) public useKeeper countCall("harvestTend") {
    expectedOut = bound(expectedOut, 0, 10 * 1e18);
    (, uint256 gain) = vaultCompoundable.harvest(reward, expectedOut);
    if (gain == 0) {
      ghost_zeroGain += 1;
    } else {
      ghost_gainSum += gain;
      vaultCompoundable.tend();
    }

    if (block.timestamp > vaultCompoundable.unlockAt()) {
      vaultCompoundable.sync();
    }
  }
}
