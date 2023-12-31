pragma solidity ^0.8.4;

// interfaces
import { ERC20Mock } from "../../mocks/ERC20.m.sol";
import { IRewardsController } from
  "../../../src/providers/aaveV3/external/IRewardsController.sol";

contract RewardsControllerMock is IRewardsController {
  uint256 public constant CLAIM_AMOUNT = 12345;
  ERC20Mock public aave;
  ERC20Mock public aToken;

  constructor(address _aToken, address _aave) {
    aave = ERC20Mock(_aave);
    aToken = ERC20Mock(_aToken);
  }

  function claimAllRewards(address[] calldata, address to)
    external
    override
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts)
  {
    uint256 amount = aToken.balanceOf(msg.sender) > 0 ? CLAIM_AMOUNT : 0;

    aave.mint(to, amount);

    rewardsList = new address[](1);
    rewardsList[0] = address(aave);

    claimedAmounts = new uint256[](1);
    claimedAmounts[0] = amount;
  }
}
