// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { Owned } from "solmate/auth/Owned.sol";
import { ERC4626Harvest } from "./ERC4626Harvest.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

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
    ERC4626Harvest _vault = ERC4626Harvest(payload.vault);
    address asset = IERC4626(payload.vault).asset();

    uint256 rewardAmount = _vault.harvest(IERC20(payload.reward));
    _vault.swap(
      IERC20(payload.reward),
      IERC20(asset),
      rewardAmount,
      payload.minAmountOut
    );
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
