// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IStargatePool } from "../../../src/providers/stargate/external/IStargatePool.sol";
import { ERC20Mock } from "../../mocks/ERC20.m.sol";
import "forge-std/console2.sol";

contract StargatePoolMock is IStargatePool {
  uint256 public poolId;

  ERC20Mock public lpToken;
  ERC20Mock public underlying;

  constructor(uint256 poolId_, ERC20Mock underlying_, ERC20Mock lpToken_) {
    poolId = poolId_;
    lpToken = lpToken_;
    underlying = underlying_;
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
    if (totalSupply() == 0 || totalLiquidity() == 0) {
      return _amountLP * 2;
    }

    return _amountLP * totalLiquidity() / totalSupply();
  }

  function amountLDtoLP(uint256 _amountLD) public view returns (uint256) {
    if (totalLiquidity() == 0 || totalLiquidity() == 0) {
      return _amountLD / 2;
    }
    return _amountLD * totalSupply() / totalLiquidity();
  }

  function addLiquidity(uint256 _amountLD, address _to) external {
    ERC20Mock(underlying).transferFrom(msg.sender, address(this), _amountLD);

    lpToken.mint(_to, amountLDtoLP(_amountLD));
  }

  function instantRedeemLocal(uint256 _amountLP, address _to) external {
    lpToken.burn(msg.sender, _amountLP);

    ERC20Mock(underlying).transfer(msg.sender, amountLPtoLD(_amountLP));
  }
}
