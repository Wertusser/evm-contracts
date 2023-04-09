// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStargatePool } from "../../../src/providers/stargate/external/IStargatePool.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import "forge-std/console2.sol";
import "../../mocks/ERC20.m.sol";

contract StargatePoolMock is IStargatePool {
  uint256 public poolId;

  WERC20Mock public lpToken;
  ERC20Mock public underlying;

  constructor(uint256 poolId_, ERC20Mock underlying_) {
    poolId = poolId_;
    underlying = underlying_;
    lpToken = new WERC20Mock(underlying);
    underlying.approve(address(lpToken), type(uint256).max);
  }

  function token() external view returns (address) {
    return address(underlying);
  }

  function totalSupply() public view returns (uint256) {
    return lpToken.totalSupply();
  }

  function totalLiquidity() public view returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  function convertRate() public view returns (uint256) {
    return 1;
  }

  function amountLPtoLD(uint256 _amountLP) public view returns (uint256) {
    return _amountLP;
  }

  function amountLDtoLP(uint256 _amountLD) public view returns (uint256) {
    return _amountLD;
  }

  function addLiquidity(uint256 _amountLD, address _to) external {
    underlying.transferFrom(msg.sender, address(this), _amountLD);
    lpToken.wrap(_amountLD);
    lpToken.transfer(_to, _amountLD);
  }

  function instantRedeemLocal(uint256 _amountLP, address _to) external {
    lpToken.transferFrom(msg.sender, address(this), _amountLP);
    lpToken.unwrap(_amountLP);
    underlying.transfer(_to, _amountLP);
  }
}
