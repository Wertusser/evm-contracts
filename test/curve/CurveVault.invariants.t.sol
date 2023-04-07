pragma solidity ^0.8.13;

import "../ERC4626.invariants.t.sol";

import { ERC20Mock } from "../mocks/ERC20.m.sol";
import { SwapperMock } from "../mocks/Swapper.m.sol";
import { CurveVault } from "../../src/providers/curve/CurveVault.sol";
import { ISwapper } from "../../src/periphery/Swapper.sol";
import { FeesController } from "../../src/periphery/FeesController.sol";
import { CurvePoolMock } from "./mocks/CurvePool.m.sol";
import { CurveGaugeMock } from "./mocks/CurveGauge.m.sol";

contract CurveVaultInvariants is ERC4626Invariants {
  ERC20Mock public lpToken;
  ERC20Mock public underlying;
  ERC20Mock public reward;
  CurvePoolMock public pool;
  CurveGaugeMock public gauge;
  ISwapper public swapper;
  FeesController public feesController;
  CurveVault public vault;

  function setUp() public {
    reward = new ERC20Mock();
    underlying = new ERC20Mock();
    lpToken = new ERC20Mock();
    pool = new CurvePoolMock(underlying, new ERC20Mock(), lpToken);
    gauge = new CurveGaugeMock(reward, lpToken);

    swapper = new SwapperMock(reward, underlying);
    feesController = new FeesController(msg.sender);

    vault = new CurveVault(
        IERC20(underlying),
        IERC20(reward),
        pool,
        gauge,
        0,
        2,
        swapper,
        address(feesController),
        msg.sender,
        msg.sender,
        msg.sender
    );

    setVault(vault);

    excludeContract(address(underlying));
    excludeContract(address(reward));
    excludeContract(address(pool));
    excludeContract(address(gauge));
    excludeContract(address(feesController));
    excludeContract(address(swapper));
  }
}
