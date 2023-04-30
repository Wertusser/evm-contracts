pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ERC20.m.sol";

contract StakePoolMock {
  ERC20Mock public rewardsToken;
  ERC20Mock public stakingToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 7 days;

  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) public _balances;

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);

  /* ========== CONSTRUCTOR ========== */

  constructor(ERC20Mock _stakingToken, ERC20Mock _rewardsToken) {
    rewardsToken = _rewardsToken;
    stakingToken = _stakingToken;
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== VIEWS ========== */

  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view virtual returns (uint256) {
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view virtual returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    uint256 timeDiff = lastTimeRewardApplicable() - lastUpdateTime;
    uint256 rewardDelta = timeDiff * rewardRate * 1e18 / _totalSupply;
    return rewardPerTokenStored + rewardDelta;
  }

  function pendingReward(address account) public view virtual returns (uint256 pendingReward_) {
    uint256 userBalance = _balances[account];
    uint256 rewardRateDiff = rewardPerToken() - userRewardPerTokenPaid[account];
    pendingReward_ = userBalance * rewardRateDiff / 1e18;
  }

  function earned(address account) public view virtual returns (uint256) {
    return rewards[account] + pendingReward(account);
  }

  function getRewardForDuration() external view virtual returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function depositStake(uint256 amount) public updateReward(msg.sender) {
    // require(amount > 0, "Cannot stake 0");
    _totalSupply += amount;
    _balances[msg.sender] += amount;
    stakingToken.transferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdrawStake(uint256 amount) public updateReward(msg.sender) {
    // require(amount > 0, "Cannot withdraw 0");
    _totalSupply -= amount;
    _balances[msg.sender] -= amount;
    stakingToken.transfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function collectRewardTokens() public updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.transfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function addRewardTokens(uint256 reward) public updateReward(address(0)) {
    rewardsToken.mint(address(this), reward);

    if (block.timestamp >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / rewardsDuration;
    }

    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;
    emit RewardAdded(reward);
  }
}
