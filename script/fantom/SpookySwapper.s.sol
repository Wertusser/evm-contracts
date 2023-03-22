pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC20} from '../../src/periphery/ERC20.sol';
import "forge-std/interfaces/IERC20.sol";
import {SpookySwapper, IUniswapV2Router02} from "../../src/swappers/SpookySwapper.sol";
import {StargateVault} from "../../src/providers/stargate/StargateVault.sol";

contract DeployScript is Script {
    function run() public payable returns (SpookySwapper deployed) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        IERC20 STG = IERC20(address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590));
        IERC20 USDC = IERC20(address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75));
        uint256 STG_AMOUNT = 10 ** 18;
        IUniswapV2Router02 router = IUniswapV2Router02(address(0x31F63A33141fFee63D4B26755430a390ACdD8a4d));

        vm.startBroadcast(deployerPrivateKey);

        console2.log("broadcaster", vm.addr(deployerPrivateKey));

        // deployed = new SpookySwapper(router);
        // // deployed = SpookySwapper(address(0xDbf7876C13e765694A7aCf8Ac01284c3eF3aC810));

        // uint256 amountOut = deployed.previewSwap(STG, USDC, STG_AMOUNT);
        // console2.log("preview STG -> USDC", amountOut);

        // STG.approve(address(deployed), STG_AMOUNT);
        // uint256 realOut = deployed.swap(STG, USDC, STG_AMOUNT, amountOut);
        // console2.log("swap STG -> USDC", realOut);

        deployed = SpookySwapper(0x85a5F96a3a8dE92E1187516B8F27c29F265362f1);
        StargateVault vault = StargateVault(address(0x364F0dd479942D9a9B4a63C0b2b1700F31c9ae0B));
        vault.setSwapper(deployed);
        vault.harvest(0);
        vm.stopBroadcast();
    }
}
