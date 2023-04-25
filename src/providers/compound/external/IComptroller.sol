// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./ICERC20.sol";

interface IComptroller {
  function getAllMarkets() external view returns (ICERC20[] memory);

  function allMarkets(uint256 index) external view returns (ICERC20);

  function mintGuardianPaused(ICERC20 cToken) external view returns (bool);

  // Venus methods

  function getXVSAddress() external view returns (address);

  function claimVenus(address holder) external;

  function venusAccrued(address user) external view returns (uint256 venusRewards);
}
