// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20 as IIERC20} from "forge-std/interfaces/IERC20.sol";

import {ERC20Mock} from "../mocks/ERC20.m.sol";
import {StargateVault} from "../../src/providers/stargate/StargateVault.sol";
import {ISwapper} from "../../src/Swapper.sol";
import {DummySwapper} from "../../src/swappers/DummySwapper.sol";
import {StargatePoolMock} from "./mocks/Pool.m.sol";
import {StargateRouterMock} from "./mocks/Router.m.sol";
import {StargateLPStakingMock} from "./mocks/LPStaking.m.sol";

contract StargateVaultTest is Test {
    ERC20Mock public lpToken;
    ERC20Mock public underlying;
    ERC20Mock public reward;

    StargatePoolMock public poolMock;
    StargateRouterMock public routerMock;
    StargateLPStakingMock public stakingMock;

    ISwapper public swapper;

    StargateVault public vault;

    function setUp() public {
        lpToken = new ERC20Mock();
        underlying = new ERC20Mock();
        reward = new ERC20Mock();

        poolMock = new StargatePoolMock(0, underlying, lpToken);
        routerMock = new StargateRouterMock(poolMock);
        stakingMock = new StargateLPStakingMock(lpToken, reward);

        swapper = new DummySwapper();

        vault = new StargateVault(
          IIERC20(address(underlying)),
          poolMock,
          routerMock,
          stakingMock,
          0,
          IIERC20(address(lpToken)),
          IIERC20(address(reward)),
          swapper
        );
    }

    function testSingleDepositWithdraw(uint128 amount) public {
        vm.assume(amount > 0);
        uint256 aliceUnderlyingAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice);

        // Expect exchange rate to be 1:1 on initial deposit.
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.withdraw(aliceUnderlyingAmount, alice, alice);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testSingleMintRedeem(uint128 amount) public {
        vm.assume(amount > 0);
        uint256 aliceShareAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceShareAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceShareAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceShareAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceUnderlyingAmount = vault.mint(aliceShareAmount, alice);

        // Expect exchange rate to be 1:1 on initial mint.
        assertEq(aliceShareAmount, aliceUnderlyingAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceUnderlyingAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.redeem(aliceShareAmount, alice, alice);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testFailDepositWithNotEnoughApproval(uint128 amountA, uint128 amountB) public {
        vm.assume(amountA < amountB);
        underlying.mint(address(this), amountA);
        underlying.approve(address(vault), amountA);
        assertEq(underlying.allowance(address(this), address(vault)), amountA);

        vault.deposit(amountB, address(this));
    }

    function testFailWithdrawWithNotEnoughUnderlyingAmount(uint128 amountA, uint128 amountB) public {
        vm.assume(amountA < amountB);
        underlying.mint(address(this), amountA);
        underlying.approve(address(vault), amountA);

        vault.deposit(amountA, address(this));

        vault.withdraw(amountB, address(this), address(this));
    }

    function testFailRedeemWithNotEnoughShareAmount(uint128 amountA, uint128 amountB) public {
        vm.assume(amountA < amountB);
        underlying.mint(address(this), amountA);
        underlying.approve(address(vault), amountA);

        vault.deposit(amountA, address(this));

        vault.redeem(amountB, address(this), address(this));
    }

    function testFailWithdrawWithNoUnderlyingAmount(uint128 amount) public {
        vm.assume(amount > 0);
        vault.withdraw(amount, address(this), address(this));
    }

    function testFailRedeemWithNoShareAmount(uint128 amount) public {
        vault.redeem(amount, address(this), address(this));
    }

    function testFailDepositWithNoApproval(uint128 amount) public {
        vm.assume(amount > 0);
        vault.deposit(amount, address(this));
    }

    function testFailMintWithNoApproval(uint128 amount) public {
        vm.assume(amount > 0);
        vault.mint(amount, address(this));
    }

    function testMintZero() public {
        vault.mint(0, address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function testWithdrawZero() public {
        vault.withdraw(0, address(this), address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    // function testVaultInteractionsForSomeoneElse(
    //     uint64 amountA,
    //     uint64 amountB,
    //     uint64 yield
    // ) public {
    //     vm.assume(amountA > 1e18);
    //     vm.assume(amountB > 1e18);
    //     vm.assume(yield > 1e18);
    //     // init 2 users with a 1e18 balance
    //     address alice = address(0xABCD);
    //     address bob = address(0xDCBA);
    //     underlying.mint(alice, amountA);
    //     underlying.mint(bob, amountB);

    //     vm.prank(alice);
    //     underlying.approve(address(vault), amountA);

    //     vm.prank(bob);
    //     underlying.approve(address(vault), amountB);

    //     // alice deposits for bob
    //     vm.prank(alice);
    //     vault.deposit(amountA, bob);

    //     assertEq(vault.balanceOf(alice), 0);
    //     assertEq(vault.balanceOf(bob), amountA);
    //     assertEq(underlying.balanceOf(alice), 0);

    //     // bob mint for alice
    //     uint256 sharesBefore = vault.convertToShares(amountB);
    //     vm.prank(bob);
    //     vault.mint(sharesBefore, alice);
    //     assertEq(vault.balanceOf(alice), amountB);
    //     assertEq(vault.balanceOf(bob), amountA);
    //     assertEq(underlying.balanceOf(bob), 0);

    //     underlying.mint(address(lendingPool), yield);
    //     aToken.mint(address(vault), yield);

    //     // alice redeem for bob
    //     uint256 sharesAfter = vault.convertToShares(amountB);
    //     vm.prank(alice);
    //     vault.redeem(sharesAfter, bob, alice);
    //     assertEq(vault.balanceOf(alice), 0);
    //     assertEq(vault.balanceOf(bob), amountA);
    //     assertEq(underlying.balanceOf(bob), amountB);

    //     // bob withdraw for alice
    //     vm.prank(bob);
    //     vault.withdraw(amountA, alice, bob);
    //     assertEq(vault.balanceOf(alice), 0);
    //     assertEq(vault.balanceOf(bob), 0);
    //     assertEq(underlying.balanceOf(alice), amountA);
    // }
}
