pragma solidity ^0.8.4;

import { ERC20, IERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock, WERC20Mock } from "../../mocks/ERC20.m.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import { IPool } from "../../../src/providers/aaveV3/external/IPool.sol";

contract PoolMock is IPool {
  mapping(address => address) internal reserveAToken;
  ERC20Mock public asset;
  WERC20Mock public aToken;

  constructor(ERC20Mock asset_) {
    asset = asset_;
    aToken = new WERC20Mock(asset);
    reserveAToken[address(asset)] = address(aToken);

    asset.approve(address(aToken), type(uint256).max);
  }

  function supply(address, /*asset*/ uint256 amount, address owner, uint16 /*refCode*/ )
    external
    override
  {
    asset.transferFrom(owner, address(this), amount);
    aToken.wrap(amount);
    aToken.transfer(owner, amount);
  }

  function withdraw(address, /*asset*/ uint256 amount, address to)
    external
    override
    returns (uint256)
  {
    aToken.transferFrom(msg.sender, address(this), amount);
    aToken.unwrap(amount);
    asset.transfer(to, amount);
    return amount;
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
