pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "forge-std/interfaces/IERC20.sol";
import { UniV2Swapper, IUniswapV2Router02 } from "../../src/swappers/UniV2Swapper.sol";
import { StargateVault } from "../../src/providers/stargate/StargateVault.sol";

contract DeployScript is Script {
  function run() public payable returns (UniV2Swapper deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
    IERC20 STG = IERC20(address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590));
    IERC20 WFTM = IERC20(address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83));
    IERC20 USDC = IERC20(address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75));
    uint256 STG_AMOUNT = 10 ** 15;

    IUniswapV2Router02 router =
      IUniswapV2Router02(address(0x31F63A33141fFee63D4B26755430a390ACdD8a4d));

    vm.startBroadcast(deployerPrivateKey);

    console2.log("broadcaster", vm.addr(deployerPrivateKey));

    deployed = new UniV2Swapper(router);

    address[] memory path = new address[](2);
    path[0] = address(STG);
    // path[1] = address(WFTM);
    path[1] = address(USDC);

    console2.log("preview path:", deployed.previewPath(STG_AMOUNT, path));

    deployed.definePath(STG, USDC, path);
    console2.log("Is path defined:", deployed.isPathDefined(STG, USDC));
    console2.log("Is reverse path defined:", deployed.isPathDefined(USDC, STG));

    uint256 amountOut = deployed.previewSwap(STG, USDC, STG_AMOUNT);
    console2.log("preview swap:", amountOut);

    STG.approve(address(deployed), STG_AMOUNT);
    uint256 realOut = deployed.swap(STG, USDC, STG_AMOUNT, amountOut * 99 / 100);
    console2.log("swap STG -> USDC", realOut);

    // StargateVault vault =
    //   StargateVault(address(0x364F0dd479942D9a9B4a63C0b2b1700F31c9ae0B));
    // vault.setSwapper(deployed);
    // vault.harvest(STG, 0);
    vm.stopBroadcast();
  }
}
