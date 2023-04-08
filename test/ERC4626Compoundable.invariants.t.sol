pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC4626 } from "../src/periphery/ERC4626.sol";
import { Depositor } from "./actors/Depositor.sol";
import { Keeper } from "./actors/Keeper.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ERC4626, ERC4626Compoundable } from "../src/periphery/ERC4626Compoundable.sol";
import { IERC4626 } from "../src/periphery/ERC4626.sol";
import { AddressSet, LibAddressSet } from "../src/utils/AddressSet.sol";


abstract contract ERC4626CompoundableInvariants is Test {
  IERC4626 public _vault;
  Depositor public depositor;
  address constant KEEPER_ADDRESS_MOCK = address(0x12341234);

  function setVault(IERC4626 vault_, IERC20 reward) public {
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
    // selectors[7] = Keeper.harvest.selector;
    // selectors[8] = Keeper.tend.selector;

    targetSelector(FuzzSelector({ addr: address(depositor), selectors: selectors }));
    excludeContract(address(_vault));
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

  function accumulateProfit(uint256 balance, address caller)
    external
    view
    returns (uint256)
  {
    ERC4626Compoundable v = ERC4626Compoundable(address(_vault));
    uint256 profit = v.pnl(caller) > 0 ? uint256(v.pnl(caller)) : 0;
    return balance + profit;
  }

  function accumulateLoss(uint256 balance, address caller)
    external
    view
    returns (uint256)
  {
    ERC4626Compoundable v = ERC4626Compoundable(address(_vault));
    uint256 loss = v.pnl(caller) < 0 ? uint256(-v.pnl(caller)) : 0;
    return balance + loss;
  }

  function invariant_callSummary() public {
    depositor.callDepositorSummary();
  }

  function invariant_totalAssetsSolvency() public {
    bool isSolvent = depositor.ghost_depositSum() >= depositor.ghost_withdrawSum();
    assertTrue(isSolvent);

    uint256 totalAssets_ = depositor.ghost_depositSum() - depositor.ghost_withdrawSum();
    assertEq(_vault.totalAssets(), totalAssets_);
  }

  function invariant_sharesZeroOverflow() public {
    uint256 sumOfShares = depositor.reduceActors(0, this.accumulateShareBalance);
    assertEq(_vault.totalSupply(), sumOfShares);
  }

  function invariant_sharesIsSolvent() public {
    uint256 sumOfAssets = depositor.reduceActors(0, this.accumulateAssetBalance);
    assertEq(_vault.totalAssets(), sumOfAssets);
  }

  function invariant_totalAssetsShareRelation() public {
    assertGe(_vault.totalAssets(), _vault.totalSupply());
  }

  function invariant_zeroSumPnl() public {
    uint256 sumOfProfit = depositor.reduceActors(0, this.accumulateProfit);
    uint256 sumOfLoss = depositor.reduceActors(0, this.accumulateLoss);
    assertEq(sumOfProfit, sumOfLoss);
  }
}
