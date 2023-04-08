pragma solidity ^0.8.4;

import { ERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock, WERC20Mock } from "../../mocks/ERC20.m.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import { IPool } from "../../../src/providers/aaveV3/external/IPool.sol";

contract PoolMock is IPool, LpPoolMock {
  mapping(address => address) internal reserveAToken;

  constructor(ERC20Mock asset_) LpPoolMock(asset_) {
  }

  function supply(address, uint256 amount, address, uint16) external override {
    addLiquidityToPool(amount);
  }

  function withdraw(address, uint256 amount, address to)
    external
    override
    returns (uint256)
  {
    return removeLiquidityFromPool(amount);
  }

  function getReserveData(address)
    external
    view
    override
    returns (IPool.ReserveData memory data)
  {
    /// active pool Aave V3 config
    data.configuration =
      ReserveConfigurationMap(379853412004453730017650325597649023837875453566284);
    data.aTokenAddress = reserveAToken[address(this)];
  }
}
