// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStargatePool } from "../../../src/providers/stargate/external/IStargatePool.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import "forge-std/console2.sol";
import "../../mocks/ERC20.m.sol";

contract StargatePoolMock is IStargatePool, LpPoolMock {
  uint256 public poolId;

  ERC20Mock public lpToken;
  ERC20Mock public underlying;

  constructor(uint256 poolId_, ERC20Mock underlying_, ERC20Mock lpToken_) LpPoolMock(underlying_) {
    poolId = poolId_;
    lpToken = lpToken_;
    underlying = underlying_;
  }

  function token() external view returns (address) {
    return address(underlying);
  }

/// TODO: WTF
  function totalSupply() public view override(ERC20, IERC20, IStargatePool) returns (uint256) {
    return this.totalSupply();
  }

  function totalLiquidity() public view returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  function convertRate() public view returns (uint256) {
    return 1;
  }

  function amountLPtoLD(uint256 _amountLP) public view returns (uint256) {
    return convertToAssets(_amountLP);
  }

  function amountLDtoLP(uint256 _amountLD) public view returns (uint256) {
    return convertToShares(_amountLD);
  }

  function addLiquidity(uint256 _amountLD, address _to) external {
    addLiquidityToPool(_amountLD);
  }

  function instantRedeemLocal(uint256 _amountLP, address _to) external {
    removeLiquidityFromPool(_amountLP);
  }
}
