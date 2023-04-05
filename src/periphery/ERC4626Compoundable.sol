// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./ERC4626Controllable.sol";
import "./Swapper.sol";

abstract contract ERC4626Compoundable is ERC4626Controllable {
  /// @notice Swapper contract
  ISwapper public swapper;

  ///@notice total earned amount. Value changes after every tend() call
  uint256 public totalEarned;
  ///@notice block timestamp of last tend() call
  uint256 public compoundAt;
  ///@notice block timestamp of contract creation
  uint256 public createdAt;

  bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

  mapping(address => uint256) public depositOf;
  mapping(address => uint256) public withdrawOf;

  constructor(
    IERC20 asset_,
    ISwapper swapper_,
    address keeper_,
    address management_,
    address emergency_
  ) ERC4626Controllable(asset_, management_, emergency_) {
    swapper = swapper_;
    createdAt = block.timestamp;
    compoundAt = block.timestamp;

    _grantRole(KEEPER_ROLE, keeper_);
  }

  event Harvest(address indexed executor, uint256 amountReward, uint256 amountWant);
  event Tend(address indexed executor, uint256 amountWant, uint256 amountShares);
  event KeeperUpdated(address newKeeper);
  event SwapperUpdated(address newSwapper);

  function setSwapper(ISwapper nextSwapper) public onlyRole(MANAGEMENT_ROLE) {
    swapper = nextSwapper;

    emit SwapperUpdated(address(swapper));
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= compoundAt, "Unexpected timestamp");
    uint256 timeElapsed = timestamp - compoundAt;

    uint256 totalTime = compoundAt - createdAt;

    if (totalTime > 0) {
      return totalEarned * timeElapsed / totalTime;
    } else {
      return 0;
    }
  }

  function pnl(address user) public view returns (int256) {
    uint256 totalDeposited = depositOf[user];
    uint256 totalWithdraw = withdrawOf[user] + this.maxWithdraw(user);

    return int256(totalWithdraw) - int256(totalDeposited);
  }

  function harvest(IERC20 reward, uint256 swapAmountOut)
    public
    onlyRole(KEEPER_ROLE)
    returns (uint256 wantAmount)
  {
    uint256 rewardAmount = _harvest(reward);

    if (rewardAmount > 0) {
      wantAmount = swapper.swap(reward, _asset, rewardAmount, swapAmountOut);
    } else {
      wantAmount = 0;
    }

    emit Harvest(msg.sender, rewardAmount, wantAmount);
  }

  function tend() public onlyRole(KEEPER_ROLE) returns (uint256 sharesAdded) {
    (uint256 wantAmount, uint256 sharesAdded_) = _tend();
    sharesAdded = sharesAdded_;

    totalEarned += wantAmount;
    compoundAt = block.timestamp;

    emit Tend(msg.sender, wantAmount, sharesAdded);
  }

  /**
   * @dev Deposit/mint common workflow.
   */
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    virtual
    override
  {
    _asset.transferFrom(caller, address(this), assets);
    _mint(receiver, shares);

    depositOf[receiver] += assets;

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Withdraw/redeem common workflow.
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }

    _burn(owner, shares);
    _asset.transfer(receiver, assets);

    withdrawOf[receiver] += assets;

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  function _harvest(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function _tend() internal virtual returns (uint256 wantAmount, uint256 sharesAdded);
}
