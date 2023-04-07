pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC4626 } from "../src/periphery/ERC4626.sol";
import { ERC4626Handler } from "./ERC4626.invariants.t.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { ERC4626, ERC4626Compoundable } from "../src/periphery/ERC4626Compoundable.sol";
import { IERC4626 } from "../src/periphery/ERC4626.sol";
import { AddressSet, LibAddressSet } from "../src/utils/AddressSet.sol";

contract ERC4626CompoundableHandler is ERC4626Handler {
  IERC20 public reward;
  ERC4626Compoundable public vaultCompoundable;
  address public keeper;

  uint256 public ghost_gainSum;

  constructor(IERC4626 _vault, IERC20 _reward, address keeper_) ERC4626Handler(_vault) {
    reward = _reward;
    vaultCompoundable = ERC4626Compoundable(address(_vault));
    keeper = keeper_;
  }

  function showActorPnl(address actor) external view {
    int256 currentPnl = vaultCompoundable.pnl(actor);
    uint256 profit = currentPnl > 0 ? uint256(currentPnl) : 0;
    uint256 loss = currentPnl < 0 ? uint256(-currentPnl) : 0;
    if (profit > 0 || loss > 0) {
      console.log(actor, profit, loss);
    }
  }

  function callSummary() external override {
    console.log("Vault summary:");
    console.log("-------------------");
    console.log("total assets", vaultCompoundable.totalAssets());
    console.log("total shares", vaultCompoundable.totalSupply());
    console.log("real assets", ghost_depositSum + ghost_gainSum - ghost_withdrawSum);
    console.log("\nTotal summary:");
    console.log("-------------------");
    console.log("total actors", actorsCount());
    console.log("total deposit", ghost_depositSum);
    console.log("total withdraw", ghost_withdrawSum);
    console.log("total gain", ghost_gainSum);
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
    console.log("harvest", calls["harvest"]);
    console.log("tend", calls["tend"]);
    console.log("\nPnL:");
    console.log("-------------------");
    forEachActor(this.showActorPnl);
  }

  function harvest(uint256 expectedOut)
    public
    countCall("harvest")
  {
    vm.prank(keeper);
    ghost_gainSum += vaultCompoundable.harvest(reward, expectedOut);
  }

  function tend() public countCall("tend") {
    vm.prank(keeper);
    vaultCompoundable.tend();
  }
}

abstract contract ERC4626CompoundableInvariants is Test {
  IERC4626 public _vault;
  ERC4626CompoundableHandler public handler;
  address constant KEEPER_ADDRESS_MOCK = address(0x12341234);

  function setVault(IERC4626 vault_, IERC20 reward) public {
    _vault = vault_;
    handler = new ERC4626CompoundableHandler(_vault, reward, KEEPER_ADDRESS_MOCK);
    bytes4[] memory selectors = new bytes4[](9);

    selectors[0] = ERC4626Handler.deposit.selector;
    selectors[1] = ERC4626Handler.withdraw.selector;
    selectors[2] = ERC4626Handler.mint.selector;
    selectors[3] = ERC4626Handler.redeem.selector;
    selectors[4] = ERC4626Handler.approve.selector;
    selectors[5] = ERC4626Handler.transfer.selector;
    selectors[6] = ERC4626Handler.transferFrom.selector;
    selectors[7] = ERC4626CompoundableHandler.harvest.selector;
    selectors[8] = ERC4626CompoundableHandler.tend.selector;

    targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
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
    handler.callSummary();
  }

  function invariant_totalAssetsSolvency() public {
    bool isSolvent = handler.ghost_depositSum() >= handler.ghost_withdrawSum();
    assertTrue(isSolvent);

    uint256 totalAssets_ = handler.ghost_depositSum() - handler.ghost_withdrawSum();
    assertEq(_vault.totalAssets(), totalAssets_);
  }

  function invariant_sharesZeroOverflow() public {
    uint256 sumOfShares = handler.reduceActors(0, this.accumulateShareBalance);
    assertEq(_vault.totalSupply(), sumOfShares);
  }

  function invariant_sharesIsSolvent() public {
    uint256 sumOfAssets = handler.reduceActors(0, this.accumulateAssetBalance);
    assertEq(_vault.totalAssets(), sumOfAssets);
  }

  function invariant_totalAssetsShareRelation() public {
    assertGe(_vault.totalAssets(), _vault.totalSupply());
  }

  function invariant_zeroSumPnl() public {
    uint256 sumOfProfit = handler.reduceActors(0, this.accumulateProfit);
    uint256 sumOfLoss = handler.reduceActors(0, this.accumulateLoss);
    assertEq(sumOfProfit, sumOfLoss);
  }
}
