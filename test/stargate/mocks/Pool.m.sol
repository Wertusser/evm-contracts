// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStargatePool } from "../../../src/providers/stargate/external/IStargatePool.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import "forge-std/console2.sol";
import "../../mocks/ERC20.m.sol";

contract StargatePoolMock is IStargatePool {
  uint256 public poolId;

  ERC20Mock public lpToken;
  ERC20Mock public underlying;

  constructor(uint256 poolId_, ERC20Mock underlying_) {
    poolId = poolId_;
    underlying = underlying_;
    lpToken = new ERC20Mock();
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
    lpToken.mint(_to, _amountLD);
  }

  function instantRedeemLocal(uint256 _amountLP, address _to) external {
    lpToken.burn(msg.sender, _amountLP);
    underlying.transfer(_to, _amountLP);
  }

  function balanceOf(address owner) external view override returns (uint256) {
    return lpToken.balanceOf(owner);
  }

  function approve(address recipient, uint256 amount) external override {
    lpToken.setAllowance(msg.sender, recipient,  amount);
  }

  function transfer(address to, uint256 amount) external {
    transferFrom(msg.sender, to, amount);
  }

  function transferFrom(address from, address to, uint256 amount) public {
    lpToken.burn(from, amount);
    lpToken.mint(to, amount);
  }
}
