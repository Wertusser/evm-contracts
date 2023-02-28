// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStargateRouter {
    function addLiquidity(uint256 _from, uint256 _amountLD, address _to) external;

    function instantRedeemLocal(uint256 _from, uint256 _amountLP, address _to) external returns (uint256);
}