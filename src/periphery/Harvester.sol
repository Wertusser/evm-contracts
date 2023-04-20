// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { Owned } from "solmate/auth/Owned.sol";
import { IERC4626Compoundable } from "./ERC4626Compoundable.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract Harvester is Owned {
  struct HarvestPayload {
    address vault;
    address reward;
    uint256 minWantAmount;
  }

  constructor(address admin_) Owned(admin_) { }

  function harvestTend(HarvestPayload memory payload)
    public
    onlyOwner
    returns (uint256 rewardAmount, uint256 wantAmount, uint256 feesAmount)
  {
    IERC4626Compoundable _vault = IERC4626Compoundable(payload.vault);
    (rewardAmount,) = _vault.harvest(IERC20(payload.reward), payload.minWantAmount);
    (wantAmount, feesAmount) = _vault.tend();
  }

  function multiHarvestTend(HarvestPayload[] calldata payloads) public onlyOwner {
    for (uint16 i = 0; i < payloads.length; i++) {
      harvestTend(payloads[i]);
    }
  }
}
