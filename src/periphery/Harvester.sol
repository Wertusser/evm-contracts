// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { Owned } from "solmate/auth/Owned.sol";
import { IERC4626Compoundable } from "./ERC4626Compoundable.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract Harvester is Owned {
  struct HarvestRequest {
    address vault;
    address reward;
    uint256 minAmountOut;
  }

  struct HarvestResponse {
    uint256 rewardAmount;
    uint256 wantAmount;
    uint256 feesAmount;
  }

  constructor(address admin_) Owned(admin_) { }

  function harvestTend(HarvestRequest memory payload)
    public
    onlyOwner
    returns (HarvestResponse memory response)
  {
    IERC4626Compoundable _vault = IERC4626Compoundable(payload.vault);

    (uint256 rewardAmount,) = _vault.harvest(IERC20(payload.reward), payload.minAmountOut);
    (uint256 wantAmount, uint256 feesAmount) = _vault.tend();

    response.rewardAmount = rewardAmount;
    response.wantAmount = wantAmount;
    response.feesAmount = feesAmount;
  }

  function multiHarvestTend(HarvestRequest[] calldata payload)
    public
    onlyOwner
    returns (HarvestResponse[] memory responses)
  {
    responses = new HarvestResponse[](payload.length);

    for (uint32 i = 0; i < payload.length; i++) {
      HarvestResponse memory response = harvestTend(payload[i]);
      responses[i] = response;
    }
  }
}
