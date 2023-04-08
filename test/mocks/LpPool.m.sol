pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ERC20.m.sol";
import "../../src/periphery/ERC4626.sol";

contract LpPoolMock is ERC4626, TestBase, StdCheats, StdUtils {
  uint256 constant YIELD_AMOUNT_PER_TOKEN = 1234567890;

  uint256 public lastYieldAt;
  ERC20Mock public assetMock;

  constructor(ERC20Mock asset_) ERC4626(asset_) {
    assetMock = asset_;
    lastYieldAt = block.timestamp;
  }

  function _vaultName(IERC20 asset_)
    internal
    view
    override
    returns (string memory vaultName)
  {
    vaultName = string.concat("ERC4626 Vault ", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_)
    internal
    view
    override
    returns (string memory vaultSymbol)
  {
    vaultSymbol = string.concat("share", asset_.symbol());
  }

  function earned() public view returns (uint256) {
    return YIELD_AMOUNT_PER_TOKEN * (block.timestamp - lastYieldAt);
  }

  function syncYield() public {
    uint256 amount = earned();
    if (amount > 0) {
      assetMock.mint(address(this), amount);
      lastYieldAt = block.timestamp;
    }
  }

  function addLiquidityToPool(uint256 amount) public returns (uint256 shares) {
    syncYield();
    return deposit(amount, msg.sender);
  }

  function removeLiquidityFromPool(uint256 sharesAmount) public returns (uint256 assets) {
    syncYield();
    return redeem(sharesAmount, msg.sender, msg.sender);
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override { }

  function beforeWithdraw(uint256 assets, uint256 shares)
    internal
    virtual
    override
    returns (uint256)
  { }
}
