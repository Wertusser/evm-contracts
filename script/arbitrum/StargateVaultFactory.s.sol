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
  address public KEEPER = address(0x777BcC85d91EcE0C641a6F03F35a2A98F4049777);

  IStargateFactory stargateFactory =
    IStargateFactory(address(0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970));
  FeesController controller =
    FeesController(address(0x6a86dDcAC0fdc7f5F80BB9566085d4c65A5E3f71));
  ISwapper swapper = ISwapper(address(0xC6A958fCDDBE22ab0B4deD7852992321A50b4453));

  IERC20 public STG = IERC20(address(0x6694340fc020c5E6B96567843da2df01b2CE1eb6));
  IERC20 public WETH = IERC20(address(0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0));
  IERC20 public USDC = IERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8));
  IERC20 public USDT = IERC20(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
  IERC20 public DAI = IERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1));
  IERC20 public FRAX = IERC20(address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F));

  function deployForPool(
    IERC20 asset,
    uint256 poolId,
    uint256 stakingId,
    uint256 firstDeposit,
    StargateVaultFactory factory
  ) public payable returns (address vault) {
    factory.createERC4626(asset, poolId, stakingId);
    vault = address(factory.computeERC4626Address(asset, poolId, stakingId));
    console2.log(asset.name(), "-", vault);

    StargateVault(vault).setKeeper(KEEPER);
    controller.setFeeBps(vault, "harvest", 1000);
    // controller.setFeeBps(vault, "deposit", 50);
    // controller.setFeeBps(vault, "withdraw",50);

    IStargatePool pool = stargateFactory.getPool(poolId);
    asset.approve(address(vault), firstDeposit);

    uint256 lpTokens = StargateVault(vault).wrap(asset, firstDeposit, ADMIN);
    pool.approve(address(vault), lpTokens);
    StargateVault(vault).deposit(lpTokens, ADMIN);
    // console.log("Balance - ", StargateVault(vault).maxZapWithdraw(ADMIN));
    // STG.transfer(vault, 1e17);
    // StargateVault(vault).harvest(STG);
    // StargateVault(vault).swap(STG, asset, 1e17, 0);
    // StargateVault(vault).tend();

    // uint256 balance = StargateVault(vault).maxWithdraw(ADMIN);
    // StargateVault(vault).withdraw(balance, ADMIN, ADMIN);

    // pool.approve(address(vault), balance);

    // StargateVault(vault).unwrap(asset, balance, ADMIN, ADMIN);
    // console.log(asset.name(), "Balance after - ", asset.balanceOf(ADMIN));

    // console2.log(asset.name(), "-", vault);
    // console.log("Treasury - ", pool.balanceOf(ADMIN));
  }

  function run() public payable returns (StargateVaultFactory deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);
    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    //
    deployed = new StargateVaultFactory(
          stargateFactory,
          IStargateRouter(address(0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614)),
          IStargateLPStaking(address(0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176)),
          controller,
          swapper,
          broadcaster
        );

    //
    deployForPool(USDC, 1, 0, 1e6, deployed);
    // deployForPool(USDT, 2, 1, 1e6, deployed);
    // deployForPool(WETH, 13, 2, 1e6, deployed);
    // deployForPool(FRAX, 7, 3, 1e6, deployed);

    vm.stopBroadcast();
  }
}
