pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "forge-std/interfaces/IERC20.sol";
import "../../src/providers/curve/external/ICurveGauge.sol";
import "../../src/providers/curve/external/ICurvePool.sol";
import "../../src/periphery/FeesController.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { CurveVaultFactory } from "../../src/providers/curve/CurveVaultFactory.sol";
import { CurveVault } from "../../src/providers/curve/CurveVault.sol";

contract DeployScript is Script {
  address public ADMIN = address(0x777BcC85d91EcE0C641a6F03F35a2A98F4049777);
  address public KEEPER = address(0x777BcC85d91EcE0C641a6F03F35a2A98F4049777);

  FeesController controller =
    FeesController(address(0x6a86dDcAC0fdc7f5F80BB9566085d4c65A5E3f71));
  ISwapper swapper = ISwapper(address(0xC6A958fCDDBE22ab0B4deD7852992321A50b4453));

  IERC20 public CRV = IERC20(address(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978));
  IERC20 public WETH = IERC20(address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
  IERC20 public USDC = IERC20(address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8));
  IERC20 public USDT = IERC20(address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
  IERC20 public DAI = IERC20(address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1));
  IERC20 public FRAX = IERC20(address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F));

  function deployForPool(
    IERC20 asset,
    uint8 coins,
    uint256 firstDeposit,
    address gauge,
    address pool,
    CurveVaultFactory factory
  ) public payable returns (address vault) {
    factory.createERC4626(ICurveGauge(gauge), ICurvePool(pool), coins);
    vault =
      address(factory.computeERC4626Address(ICurveGauge(gauge), ICurvePool(pool), coins));

    CurveVault(vault).setKeeper(KEEPER);
    controller.setFeeBps(vault, "harvest", 1000);
    // controller.setFeeBps(vault, "deposit", 50);
    // // controller.setFeeBps(vault, "withdraw",50);

    console.log(asset.name(), "Balance before - ", asset.balanceOf(ADMIN));
    asset.approve(vault, firstDeposit);

    uint256 lpTokens = CurveVault(vault).wrap(asset, firstDeposit, ADMIN);
    CurveVault(vault).asset().approve(vault, lpTokens * 2);
    CurveVault(vault).deposit(lpTokens, ADMIN);
    console.log(
      "Deposited - ",
      CurveVault(vault).previewUnwrap(asset, CurveVault(vault).maxWithdraw(ADMIN))
    );
    CRV.transfer(vault, 1e17);
    CurveVault(vault).harvest(CRV);
    // CurveVault(vault).swap(CRV, USDC, 1e17, 0);
    // CurveVault(vault).tend();
    // console.log("Balance - ", CurveVault(vault).maxZapWithdraw(ADMIN, coinId));
    CurveVault(vault).withdraw(CurveVault(vault).maxWithdraw(ADMIN), ADMIN, ADMIN);

    CurveVault(vault).unwrap(
      asset, CurveVault(vault).asset().balanceOf(ADMIN), ADMIN, ADMIN
    );
    console.log(asset.name(), "Balance after - ", asset.balanceOf(ADMIN));

    console2.log(asset.name(), "-", vault);
  }

  function run() public payable returns (CurveVaultFactory deployed) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);
    address broadcaster = vm.addr(deployerPrivateKey);
    console2.log("broadcaster", broadcaster);

    //
    deployed = new CurveVaultFactory(
          controller,
          swapper,
          broadcaster
        );

    // tricrypto
    deployForPool(
      USDT,
      3,
      1e5,
      address(0x555766f3da968ecBefa690Ffd49A2Ac02f47aa5f),
      address(0x960ea3e3C7FB317332d990873d354E18d7645590),
      deployed
    );
    // 2pool
    deployForPool(
      USDT,
      2,
      1e5,
      address(0xCE5F24B7A95e9cBa7df4B54E911B4A3Dc8CDAf6f),
      address(0x7f90122BF0700F9E7e1F688fe926940E8839F353),
      deployed
    );
    // FRAXBP
    deployForPool(
      USDC,
      2,
      1e5,
      address(0x95285Ea6fF14F80A2fD3989a6bAb993Bd6b5fA13),
      address(0xC9B8a3FDECB9D5b218d02555a8Baf332E5B740d5),
      deployed
    );
    // wsteth
    // deployForPool(
    //   USDT,
    //   2,
    //   1,
    //   1e6,
    //   address(0x098EF55011B6B8c99845128114A9D9159777d697),
    //   address(0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80),
    //   deployed
    // );

    vm.stopBroadcast();
  }
}
