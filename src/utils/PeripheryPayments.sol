// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";

abstract contract PeripheryPayments {
  using SafeTransferLib for *;

  IWETH9 public immutable WETH9;

  constructor(IWETH9 _WETH9) {
    WETH9 = _WETH9;
  }

  receive() external payable { }

  function approve(ERC20 token, address to, uint256 amount) public payable {
    token.safeApprove(to, amount);
  }

  function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
    uint256 balanceWETH9 = WETH9.balanceOf(address(this));
    require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

    if (balanceWETH9 > 0) {
      WETH9.withdraw(balanceWETH9);
      recipient.safeTransferETH(balanceWETH9);
    }
  }
  
  function wrapWETH9() public payable {
    if (address(this).balance > 0) WETH9.deposit{ value: address(this).balance }(); // wrap everything
  }

  function pullToken(ERC20 token, uint256 amount, address recipient) public payable {
    token.safeTransferFrom(msg.sender, recipient, amount);
  }

  function sweepToken(ERC20 token, uint256 amountMinimum, address recipient)
    public
    payable
  {
    uint256 balanceToken = token.balanceOf(address(this));
    require(balanceToken >= amountMinimum, "Insufficient token");

    if (balanceToken > 0) {
      token.safeTransfer(recipient, balanceToken);
    }
  }

  function refundETH() external payable {
    if (address(this).balance > 0) {
      SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
  }
}

abstract contract IWETH9 is ERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable virtual;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external virtual;
}
