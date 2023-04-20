pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import "forge-std/interfaces/IERC20.sol";
import "../../src/providers/stargate/external/IStargateLPStaking.sol";
import "../../src/providers/stargate/external/IStargateRouter.sol";
import "../../src/providers/stargate/external/IStargatePool.sol";
import "../../src/providers/stargate/external/IStargateFactory.sol";
import "../../src/periphery/FeesController.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { StargateVaultFactory } from
  "../../src/providers/stargate/StargateVaultFactory.sol";
import { StargateVault } from "../../src/providers/stargate/StargateVault.sol";

contract DeployScript is Script {
  address public ADMIN = address(0x777BcC85d91EcE0C641a6F03F35a2A98F4049777);
  IERC20 public STG = IERC20(address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590));

  IERC20 public WETH = IERC20(address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0));
  IERC20 public USDC = IERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8));
  IERC20 public USDT = IERC20(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
  IERC20 public DAI = IERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1));
  IERC20 public FRAX = IERC20(address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F));

  function deployForPool(
    IERC20 asset,
    uint256 poolId,
    uint256 stakingId,
    StargateVaultFactory factory
  ) public payable returns (address vault) {
    factory.createERC4626(asset, poolId, stakingId);
    vault = address(factory.computeERC4626Address(asset, poolId, stakingId));
    console2.log(asset.name(), "-", vault);
  }

  function run() public payable returns (StargateVaultFactory deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);
    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    deployed = new StargateVaultFactory(
          IStargateFactory(address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970)),
          IStargateRouter(address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614)),
          IStargateLPStaking(address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176)),
          FeesController(address(0x9D2AcB1D33eb6936650Dafd6e56c9B2ab0Dd680c)),
          ISwapper(address(0x85a5F96a3a8dE92E1187516B8F27c29F265362f1)),
          broadcaster
        );

    deployForPool(USDC, 1, 0, deployed);
    deployForPool(USDT, 2, 1, deployed);
    deployForPool(WETH, 13, 2, deployed);
    deployForPool(FRAX, 7, 3, deployed);

    vm.stopBroadcast();
  }
}