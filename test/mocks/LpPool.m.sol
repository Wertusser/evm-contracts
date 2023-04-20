pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ERC20.m.sol";
import "solmate/test/utils/mocks/MockERC4626.sol";

contract LpPoolMock is MockERC4626, TestBase, StdCheats, StdUtils {
  uint256 constant YIELD_AMOUNT_PER_TOKEN = 1234567890;

  uint256 public lastYieldAt;
  ERC20Mock public assetMock;

  event SyncYield(
    uint256 yieldAdded, uint256 sharesBefore, uint256 sharesAfter, uint256 timeAt
  );

  constructor(ERC20Mock asset_) MockERC4626(asset_, "TEST", "TEST") {
    assetMock = asset_;
    lastYieldAt = block.timestamp;
  }

  function earned() public view returns (uint256) {
    return YIELD_AMOUNT_PER_TOKEN * (block.timestamp - lastYieldAt);
  }

  function syncYield() public {
    uint256 amount = earned();
    if (amount > 0) {
      uint256 rateBefore = convertToAssets(1e18);
      assetMock.mint(address(this), amount);
      uint256 rateAfter = convertToAssets(1e18);

      lastYieldAt = block.timestamp;
      emit SyncYield(amount, rateBefore, rateAfter, lastYieldAt);
    }
  }

  function deposit2(uint256 amount, address receiver) public returns (uint256 shares) {
    syncYield();
    return deposit(amount, receiver);
  }

  function redeem2(uint256 sharesAmount, address receiver, address account)
    public
    returns (uint256)
  {
    return redeem(sharesAmount, receiver, account);
  }
}
