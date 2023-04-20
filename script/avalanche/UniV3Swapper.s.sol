pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "forge-std/interfaces/IERC20.sol";
import {
  UniV3Swapper,
  IUniswapV3Factory,
  IUniswapV3Router
} from "../../src/swappers/UniV3Swapper.sol";
import { StargateVault } from "../../src/providers/stargate/StargateVault.sol";

contract DeployScript is Script {
  IERC20 STG = IERC20(address(0x6694340fc020c5E6B96567843da2df01b2CE1eb6));
  IERC20 HOP = IERC20(address(0xc5102fE9359FD9a28f877a67E36B0F050d81a3CC));

  IERC20 WETH = IERC20(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
  IERC20 USDC = IERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8));
  IERC20 USDT = IERC20(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
  IERC20 DAI = IERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1));
  IERC20 FRAX = IERC20(address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F));

  uint256 AMOUNT = 1000 * 10 ** 18;

  IUniswapV3Factory factory =
    IUniswapV3Factory(address(0x1F98431c8aD98523631AE4a59f267346ea31F984));
  IUniswapV3Router router =
    IUniswapV3Router(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));

  function run() public payable returns (UniV3Swapper deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
    address[] memory path;
    uint24[] memory fee;

    vm.startBroadcast(deployerPrivateKey);

    console2.log("broadcaster", vm.addr(deployerPrivateKey));

    deployed = new UniV3Swapper(factory, router);
    console.log("UniV3 Swapper: ", address(deployed));

    path = new address[](3);
    path[0] = address(STG);
    path[1] = address(WETH);
    path[2] = address(USDC);

    fee = new uint24[](2);
    fee[0] = 3000;
    fee[1] = 500;

    console2.log("STG -> USDC:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    path = new address[](2);
    path[0] = address(STG);
    path[1] = address(WETH);

    fee = new uint24[](1);
    fee[0] = 3000;

    console2.log("STG -> WETH:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    path = new address[](3);
    path[0] = address(STG);
    path[1] = address(WETH);
    path[2] = address(USDT);

    fee = new uint24[](2);
    fee[0] = 3000;
    fee[1] = 500;

    console2.log("STG -> USDT:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    /// HOPS swaps

    path = new address[](3);
    path[0] = address(HOP);
    path[1] = address(WETH);
    path[2] = address(USDC);

    fee = new uint24[](2);
    fee[0] = 10000;
    fee[1] = 500;

    console2.log("HOP -> USDC:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    path = new address[](3);
    path[0] = address(HOP);
    path[1] = address(WETH);
    path[2] = address(USDT);

    fee = new uint24[](2);
    fee[0] = 10000;
    fee[1] = 500;

    console2.log("HOP -> USDT:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    path = new address[](3);
    path[0] = address(HOP);
    path[1] = address(WETH);
    path[2] = address(DAI);

    fee = new uint24[](2);
    fee[0] = 10000;
    fee[1] = 500;

    console2.log("HOP -> DAI:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    path = new address[](2);
    path[0] = address(HOP);
    path[1] = address(WETH);

    fee = new uint24[](1);
    fee[0] = 10000;

    console2.log("HOP -> WETH:", deployed.previewPath(AMOUNT, path, fee));
    deployed.definePath(path, fee);

    // StargateVault vault =
    //   StargateVault(address(0x364F0dd479942D9a9B4a63C0b2b1700F31c9ae0B));
    // vault.setSwapper(deployed);
    // vault.harvest(STG, 0);
    vm.stopBroadcast();
  }
}
