// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";
import "./ERC4626Vesting.sol";
import "./Swapper.sol";
import "../extensions/HarvestExt.sol";

interface IERC4626Harvest {
  function setSwapper(ISwapper nextSwapper) external;
  function expectedReturns(uint256 timestamp) external view returns (uint256);

  function harvest(IERC20 reward) external returns (uint256);
  function swap(IERC20 fromAsset, IERC20 toAsset, uint256 amountIn, uint256 minAmountOut)
    external
    returns (uint256);
  function tend() external returns (uint256, uint256);
  // function sync() external;
}

abstract contract ERC4626Harvest is IERC4626Harvest, ERC4626Vesting, HarvestExt {
  event SwapperUpdated(address newSwapper);
  event KeeperUpdated(address newKeeper);

  constructor(
    IERC20 asset_,
    string memory _name,
    string memory _symbol,
    ISwapper swapper_,
    IFeesController feesController_,
    address admin_
  )
    ERC4626Vesting(asset_, _name, _symbol, feesController_, admin_)
    HarvestExt(admin_, swapper_)
  { }

  function expectedReturns(uint256 timestamp)
    public
    view
    override(HarvestExt, IERC4626Harvest)
    returns (uint256)
  {
    return super.expectedReturns(timestamp);
  }

  function harvest(IERC20 reward)
    public
    override(HarvestExt, IERC4626Harvest)
    returns (uint256)
  {
    return super.harvest(reward);
  }

  function tend() public override(HarvestExt, IERC4626Harvest) returns (uint256, uint256) {
    return super.tend();
  }

  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
    public
    override(HarvestExt, IERC4626Harvest)
    returns (uint256)
  {
    return super.swap(assetFrom, assetTo, amountIn, minAmountOut);
  }

  function setKeeper(address account) public onlyOwner {
    keeper = account;

    emit KeeperUpdated(account);
  }

  function setSwapper(ISwapper nextSwapper) public onlyOwner {
    swapper = nextSwapper;

    emit SwapperUpdated(address(swapper));
  }
}
