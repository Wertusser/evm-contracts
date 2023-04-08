pragma solidity ^0.8.4;

import { ERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock, WERC20Mock } from "../../mocks/ERC20.m.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import { IPool } from "../../../src/providers/aaveV3/external/IPool.sol";

contract PoolMock is IPool {
  mapping(address => address) internal reserveAToken;
  ERC20Mock public asset;
  LpPoolMock public aToken;

  constructor(ERC20Mock asset_) {
    asset = asset_;
    aToken = new LpPoolMock(asset_);
    reserveAToken[address(asset_)] = address(aToken);

    // asset_.approve(address(aToken), type(uint256).max);
    // aToken.approve(address(aToken), type(uint256).max);
  }

  function supply(address, uint256 amount, address, uint16) external override {
    asset.transferFrom(msg.sender, address(this), amount);
    asset.approve(address(aToken), amount);

    uint256 shares = aToken.addLiquidityToPool(amount);
    aToken.transfer(msg.sender, shares);
  }

  function withdraw(address, uint256 amount, address to)
    external
    override
    returns (uint256)
  {
    aToken.transferFrom(msg.sender, address(this), amount);
    uint256 assets =  aToken.removeLiquidityFromPool(amount);
    
    asset.transfer(msg.sender, assets);
    return assets;
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
    data.aTokenAddress = address(aToken);
  }
}
