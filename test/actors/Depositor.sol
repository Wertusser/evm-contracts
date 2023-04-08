pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "../../src/periphery/ERC4626.sol";
import { ActorBase } from "./Actor.sol";

contract Depositor is ActorBase {
  uint256 public ghost_depositSum;
  uint256 public ghost_withdrawSum;
  uint256 public ghost_transferSum;

  uint256 public ghost_zeroDeposit;
  uint256 public ghost_zeroWithdraw;
  uint256 public ghost_zeroTransfer;

  constructor(IERC4626 _vault) ActorBase(_vault) { }

  // helper methods for actors

  function callDepositorSummary() public virtual {
    console.log("Vault summary:");
    console.log("-------------------");
    console.log("total assets", vault.totalAssets());
    console.log("total shares", vault.totalSupply());
    console.log("real assets", ghost_depositSum - ghost_withdrawSum);
    console.log("\nTotal summary:");
    console.log("-------------------");
    console.log("total actors", actorsCount());
    console.log("total deposit", ghost_depositSum);
    console.log("total withdraw", ghost_withdrawSum);
    console.log("total transfered", ghost_transferSum);
    console.log("\nZero summary:");
    console.log("-------------------");
    console.log("zero deposit", ghost_zeroDeposit);
    console.log("zero withdraw", ghost_zeroWithdraw);
    console.log("zero transfer", ghost_zeroTransfer);
    console.log("\nCall summary:");
    console.log("-------------------");
    console.log("deposit", calls["deposit"]);
    console.log("mint", calls["mint"]);
    console.log("redeem", calls["redeem"]);
    console.log("withdraw", calls["withdraw"]);
    console.log("transfer", calls["transfer"]);
    console.log("transferFrom", calls["transferFrom"]);
    console.log("approve", calls["approve"]);
  }

  // Core ERC4262 methods

  function deposit(uint256 amount) public createActor countCall("deposit") {
    amount = bound(amount, 0, IERC20(vault.asset()).balanceOf(currentActor));
    if (amount == 0) {
      ghost_zeroDeposit += 1;
    }
    vault.deposit(amount, currentActor);
    ghost_depositSum += amount;
  }

  function mint(uint256 amount) public createActor countCall("mint") {
    amount = bound(amount, 0, IERC20(vault.asset()).balanceOf(currentActor));
    if (amount == 0) {
      ghost_zeroDeposit += 1;
    }
    uint256 shares = vault.convertToShares(amount);

    vault.mint(shares, currentActor);
    ghost_depositSum += amount;
  }

  function withdraw(uint256 actorSeed, uint256 amount)
    public
    useActor(actorSeed)
    countCall("withdraw")
  {
    amount = bound(amount, 0, vault.maxRedeem(currentActor));
    if (amount == 0) {
      ghost_zeroWithdraw += 1;
    }
    uint256 shares = vault.convertToShares(amount);
    vault.withdraw(shares, currentActor, currentActor);
    ghost_withdrawSum += amount;
  }

  function redeem(uint256 actorSeed, uint256 amount)
    public
    useActor(actorSeed)
    countCall("redeem")
  {
    amount = bound(amount, 0, vault.maxRedeem(currentActor));
    if (amount == 0) {
      ghost_zeroWithdraw += 1;
    }
    vault.redeem(amount, currentActor, currentActor);
    ghost_withdrawSum += amount;
  }

  // ERC20-related methods (ERC04626 is also ERC20)

  function approve(uint256 actorSeed, uint256 spenderSeed, uint256 amount)
    public
    useActor(actorSeed)
    countCall("approve")
  {
    address spender = actorsRand(spenderSeed);

    vault.approve(spender, amount);
  }

  function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount)
    public
    useActor(actorSeed)
    countCall("transfer")
  {
    address to = actorsRand(toSeed);

    amount = bound(amount, 0, vault.balanceOf(currentActor));

    if (amount == 0) {
      ghost_zeroTransfer += 1;
    }

    vault.transfer(to, amount);
    ghost_transferSum += amount;
  }

  function transferFrom(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transferFrom") {
    address from = actorsRand(fromSeed);
    address to = actorsRand(toSeed);

    amount = bound(amount, 0, vault.balanceOf(from));
    amount = bound(amount, 0, vault.allowance(currentActor, from));

    if (amount == 0) {
      ghost_zeroTransfer += 1;
    }

    vault.transferFrom(from, to, amount);
    ghost_transferSum += amount;
  }
}
