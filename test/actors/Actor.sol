pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
import { AddressSet, LibAddressSet } from "../../src/utils/AddressSet.sol";

abstract contract ActorBase is TestBase, StdCheats, StdUtils {
  using LibAddressSet for AddressSet;

  AddressSet internal actors;
  IERC4626 public vault;

  mapping(bytes32 => uint256) public calls;

  address internal currentActor;
  uint256 public timestamp;

  modifier countCall(bytes32 key) {
    calls[key]++;
    _;
  }

  modifier createActor() {
    currentActor = msg.sender;
    actors.add(msg.sender);
    deal(vault.asset(), currentActor, 10 ** 18);

    timestamp = block.timestamp + 1;
    vm.warp(timestamp);
    vm.startPrank(currentActor);
    IERC20(vault.asset()).approve(address(vault), type(uint256).max);
    IERC20(vault).approve(address(vault), type(uint256).max);
    _;
    vm.stopPrank();
  }

  modifier useActor(uint256 actorIndexSeed) {
    currentActor = actors.rand(actorIndexSeed);

    timestamp = block.timestamp + 1;
    vm.warp(timestamp);
    vm.startPrank(currentActor);
    _;
    vm.stopPrank();
  }

  constructor(IERC4626 _vault) {
    vault = _vault;
  }
  
  function forEachActor(function(address) external func) public {
    return actors.forEach(func);
  }

  function reduceActors(
    uint256 acc,
    function(uint256,address) external returns (uint256) func
  ) public returns (uint256) {
    return actors.reduce(acc, func);
  }

  function actorsCount() public view returns(uint256) {
    return actors.count();
  }

   function actorsRand(uint256 seed) public view returns(address) {
    return actors.rand(seed);
  }
}