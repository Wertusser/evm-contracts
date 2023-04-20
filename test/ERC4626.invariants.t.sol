pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
import { Depositor } from "./actors/Depositor.sol";
import { AddressSet, LibAddressSet } from "../src/utils/AddressSet.sol";

abstract contract ERC4626Invariants is Test {
  IERC4626 public _vault;
  Depositor public depositor;

  function setVault(IERC4626 vault_) public {
    _vault = vault_;
    depositor = new Depositor(_vault);

    bytes4[] memory selectors = new bytes4[](7);

    selectors[0] = Depositor.deposit.selector;
    selectors[1] = Depositor.withdraw.selector;
    selectors[2] = Depositor.mint.selector;
    selectors[3] = Depositor.redeem.selector;
    selectors[4] = Depositor.approve.selector;
    selectors[5] = Depositor.transfer.selector;
    selectors[6] = Depositor.transferFrom.selector;

    excludeContract(address(_vault));
    targetSelector(FuzzSelector({ addr: address(depositor), selectors: selectors }));
  }

  function accumulateAssetBalance(uint256 balance, address caller)
    external
    view
    returns (uint256)
  {
    return balance + _vault.maxRedeem(caller);
  }

  function accumulateShareBalance(uint256 balance, address caller)
    external
    view
    returns (uint256)
  {
    return balance + _vault.maxWithdraw(caller);
  }

  function invariant_callSummary() public {
    depositor.callDepositorSummary();
  }

  // function invariant_totalAssetsSolvency() public {
  //   // Invariant: depositSum >= withdrawSum
  //   assertTrue(depositor.ghost_depositSum() >= depositor.ghost_withdrawSum());

  //   // Invariant:  totalAssets == depositSum - withdrawSum
  //   assertEq(
  //     _vault.totalAssets(), depositor.ghost_depositSum() - depositor.ghost_withdrawSum()
  //   );

  //   // Invariant:  totalAssets <= underlying balance of contract (with rounding)
  //   assertLe(_vault.totalAssets(), IERC20(_vault.asset()).balanceOf(address(_vault)));
  // }

  // function invariant_sharesZeroOverflow() public {
  //   uint256 sumOfShares = depositor.reduceActors(0, this.accumulateShareBalance);

  //   // Invariant: totalSupply == sum of all actor's max withdraw
  //   assertApproxEqAbs(_vault.totalSupply(), sumOfShares, 100);
  // }

  // function invariant_sharesIsSolvent() public {
  //   uint256 sumOfAssets = depositor.reduceActors(0, this.accumulateAssetBalance);

  //   // Invariant: totalAssets == sum of all actor's max redeem
  //   assertApproxEqAbs(_vault.totalAssets(), sumOfAssets, 100);
  // }

  // function invariant_totalAssetsShareRelation() public {
  //   // Invariant: convertToAssets(totalSupply) == totalAssets
  //   assertEq(_vault.convertToShares(_vault.totalAssets()), _vault.totalSupply());

  //   // Invariant: totalAssets >= totalSupply (can yield)
  //   assertGe(_vault.totalAssets(), _vault.totalSupply());
  // }
}