// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "./ERC4626Controllable.sol";
import "./Swapper.sol";

abstract contract ERC4626Compoundable is ERC4626Controllable {
    /// @notice The expected reward token from integrated provider
    IERC20 public reward;
    /// @notice Swapper contract
    ISwapper public swapper;

    ///@notice total earned amount. Value changes after every tend() call
    uint256 public totalEarned;
    ///@notice block timestamp of last tend() call
    uint256 public compoundAt;
    ///@notice block timestamp of contract creation
    uint256 public createdAt;

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor(
        IERC20 asset_,
        IERC20 reward_,
        ISwapper swapper_,
        address keeper_,
        address management_,
        address emergency_
    ) ERC4626Controllable(asset_, management_, emergency_) {
        reward = reward_;
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

    function harvest(uint256 swapAmountOut) public onlyRole(KEEPER_ROLE) returns (uint256 wantAmount) {
        uint256 rewardAmount = _harvest();
        
        if (rewardAmount > 0) {
            wantAmount = swapper.swap(reward, want, rewardAmount, swapAmountOut);
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

    function _harvest() internal virtual returns (uint256 rewardAmount);
    function _tend() internal virtual returns (uint256 wantAmount, uint256 sharesAdded);
}
