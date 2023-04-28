// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
// import { Depositor } from "./actors/Depositor.sol";
// import { Keeper } from "./actors/Keeper.sol";
// import { IERC20 } from "forge-std/interfaces/IERC20.sol";
// import { ERC4626, ERC4626Compoundable } from "../src/periphery/ERC4626Compoundable.sol";
// import { AddressSet, LibAddressSet } from "../src/utils/AddressSet.sol";

// abstract contract ERC4626CompoundableInvariants is Test {
//   IERC4626 public _vault;
//   Depositor public depositor;
//   Keeper public keeper;

//   function setVault(IERC4626 vault_, IERC20 reward) public {
//     _vault = vault_;
//     depositor = new Depositor(_vault);
//     keeper = new Keeper(ERC4626Compoundable(address(_vault)), reward);
//     bytes4[] memory depositorSelector = new bytes4[](7);
//     bytes4[] memory keeperSelector = new bytes4[](1);

//     depositorSelector[0] = Depositor.deposit.selector;
//     depositorSelector[1] = Depositor.withdraw.selector;
//     depositorSelector[2] = Depositor.mint.selector;
//     depositorSelector[3] = Depositor.redeem.selector;
//     depositorSelector[4] = Depositor.approve.selector;
//     depositorSelector[5] = Depositor.transfer.selector;
//     depositorSelector[6] = Depositor.transferFrom.selector;
//     keeperSelector[0] = Keeper.harvestTendSync.selector;

//     targetSelector(
//       FuzzSelector({ addr: address(depositor), selectors: depositorSelector })
//     );
//     targetSelector(FuzzSelector({ addr: address(keeper), selectors: keeperSelector }));
//     excludeContract(address(_vault));
//     excludeContract(address(keeper));
//   }

//   function accumulateAssetBalance(uint256 balance, address caller)
//     external
//     view
//     returns (uint256)
//   {
//     return balance + _vault.maxWithdraw(caller);
//   }

//   function accumulateShareBalance(uint256 balance, address caller)
//     external
//     view
//     returns (uint256)
//   {
//     return balance + _vault.maxRedeem(caller);
//   }

//   function accumulateProfit(uint256 balance, address caller)
//     public
//     view
//     returns (uint256)
//   {
//     ERC4626Compoundable v = ERC4626Compoundable(address(_vault));
//     uint256 profit = v.pnl(caller) > 0 ? uint256(v.pnl(caller)) : 0;
//     return balance + profit;
//   }

//   function accumulateLoss(uint256 balance, address caller) public view returns (uint256) {
//     ERC4626Compoundable v = ERC4626Compoundable(address(_vault));
//     uint256 loss = v.pnl(caller) < 0 ? uint256(-v.pnl(caller)) : 0;
//     return balance + loss;
//   }

//   function showActor(address actor) external view {
//     IERC20 asset = IERC20(_vault.asset());
//     console.log(actor);
//     console.log("Deposited: ", _vault.convertToAssets(_vault.balanceOf(actor)));
//     console.log("Shares: ", _vault.balanceOf(actor));
//     console.log("Assets:", asset.balanceOf(actor));
//     console.log("Profit: ", accumulateProfit(0, actor));
//     console.log("Loss: ", accumulateLoss(0, actor), "\n");
//   }

//   function invariant_callSummary() public {
//     depositor.callDepositorSummary();
//     keeper.callHarvestSummary();
//     console.log("\nProfit and Loss");
//     console.log("-------------------");
//     console.log("Total Profit: ", depositor.reduceActors(0, this.accumulateProfit));
//     console.log("Total Loss: ", depositor.reduceActors(0, this.accumulateLoss));
//     if (depositor.actorsCount() < 10) {
//       console.log("\nActors status:");
//       console.log("-------------------");
//       depositor.forEachActor(this.showActor);
//     }
//   }

//   function invariant_totalAssetsSolvency() public {
//     assertGe(
//       depositor.ghost_depositSum() + keeper.ghost_gainSum(),
//       depositor.ghost_withdrawSum(),
//       "Invariant: depositSum + gainSum >= withdrawSum"
//     );

//     // assertApproxEqAbs(
//     //   _vault.totalAssets(),
//     //   depositor.ghost_depositSum() + keeper.ghost_gainSum()
//     //     - depositor.ghost_withdrawSum(),
//     //   100,
//     //   "Invariant:  totalAssets == depositSum + gainSum - withdrawSum"
//     // );

//     // TODO: with linear vesting should be assertLe,
//     // also requires underlying tokens to be stored at vault

//     // assertEq(
//     //   _vault.totalAssets(),
//     //   IERC20(_vault.asset()).balanceOf(address(_vault)),
//     //   "Invariant:  totalAssets <= underlying balance of contract (with rounding)"
//     // );
//   }

//   function invariant_sharesZeroOverflow() public {
//     uint256 sumOfShares = depositor.reduceActors(0, this.accumulateShareBalance);

//     assertApproxEqAbs(
//       _vault.totalSupply(),
//       sumOfShares,
//       1e18,
//       "Invariant: totalSupply == sum of all actor's max redeem"
//     );
//   }

//   function invariant_sharesIsSolvent() public {
//     uint256 sumOfAssets = depositor.reduceActors(0, this.accumulateAssetBalance);

//     assertApproxEqAbs(
//       _vault.totalAssets(),
//       sumOfAssets,
//      1e18,
//       "Invariant: totalAssets == sum of all actor's max withdraw"
//     );
//   }

//   function invariant_totalAssetsShareRelation() public {
//     assertApproxEqAbs(
//       _vault.convertToAssets(_vault.totalSupply()),
//       _vault.totalAssets(),
//       1e18,
//       "Invariant: convertToAssets(totalSupply) == totalAssets"
//     );

//     // This can be impossible in real life case due to impermanent losses/hacks/rugs

//     // assertGe(
//     //   _vault.totalAssets(),
//     //   _vault.totalSupply(),
//     //   "Invariant: totalAssets >= totalSupply (can yield)"
//     // );
//   }

//   function invariant_zeroSumPnl() public {
//     uint256 sumOfProfit = depositor.reduceActors(0, this.accumulateProfit);
//     uint256 sumOfLoss = depositor.reduceActors(0, this.accumulateLoss);
//     if (sumOfProfit >= sumOfLoss) {
//       assertGe(
//         keeper.ghost_gainSum(),
//         sumOfProfit - sumOfLoss,
//         "Invariant: gain >= profit - loss"
//       );
//     } else {
//       console.log("WARNING: profit < loss");
//       console.log("Negative delta: ", sumOfLoss - sumOfProfit);
//     }

//     // This can be impossible in real life case due to impermanent losses/hacks/rugs

//     // assertGe(sumOfProfit, sumOfLoss, "Invariant: profit >= loss");
//     // assertEq(sumOfProfit, sumOfLoss, "Invariant: sumOfProfit == sumOfLoss");
//   }
// }
