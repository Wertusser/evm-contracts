// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IInterestRateModel {
    function getBorrowRate(uint256, uint256, uint256) external view returns (uint256);

    function getSupplyRate(uint256, uint256, uint256, uint256) external view returns (uint256);
}
