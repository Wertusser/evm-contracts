pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {console2} from 'forge-std/console2.sol';

contract UniV3Swapper is Test {
    function setUp() public {}

    function test_fail_setRouteWithEmptyPayload() public {}

    function test_fail_setRouteWithInvalidPayload() public {}

    function test_setRoute() public {}

    function test_setRoutePreviewSwap() public {}

    function test_fail_setRouteSwapWithZeroAssets() public {}

    function test_fail_setRouteSwapWithInsufficientAssets() public {}

    function test_setRouteSwap() public {}
}
