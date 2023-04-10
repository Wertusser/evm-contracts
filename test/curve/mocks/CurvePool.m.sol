pragma solidity ^0.8.4;

import { ERC20, IERC20 } from "../../../src/periphery/ERC20.sol";

import { ERC20Mock, WERC20Mock } from "../../mocks/ERC20.m.sol";
import { LpPoolMock } from "../../mocks/LpPool.m.sol";
import { ICurvePool } from "../../../src/providers/curve/external/ICurvePool.sol";

contract CurvePoolMock is ICurvePool {
  ERC20Mock public token0;
  ERC20Mock public token1;
  WERC20Mock public lpToken;

  constructor(ERC20Mock token0_, ERC20Mock token1_) {
    token0 = token0_;
    token1 = token1_;
    lpToken = new WERC20Mock(token0);
    token0.approve(address(lpToken), type(uint256).max);
  }

  function token() public view returns (address) {
    return address(lpToken);
  }

  function coins(int128 i) public view override returns (address) {
    if (i == 0) return address(token0);
    if (i == 1) return address(token1);
    require(i <= 1);
  }

  function is_killed() external view override returns (bool) {
    return false;
  }

  function get_virtual_price() external view override returns (uint256) {
    return 0;
  }

  function price_oracle() external view override returns (uint256) {
    return 0;
  }

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    payable
    override
  { }

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable override returns (uint256) {
    return 100;
  }

  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable override returns (uint256) {
    return 0;
  }

  function add_liquidity(
    address pool,
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external override { }

  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external payable override returns (uint256) {
    return 0;
  }

  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external
    payable
    override
  { }

  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
    external
    payable
    override
  { }

  function add_liquidity(uint256[] calldata amounts, uint256 min_mint_amount)
    external
    payable
    override
  {
    token0.transferFrom(msg.sender, address(this), amounts[0]);
    token1.transferFrom(msg.sender, address(this), amounts[1]);
    uint256 amount = amounts[0] > amounts[1] ? amounts[0] : amounts[1];
    lpToken.mint(msg.sender, amount);
  }

  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 max_burn_amount
  ) external override { }

  function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external
    override
  { }

  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount)
    external
    override
  {
    address token_ = coins(i);
    lpToken.burn(msg.sender, _token_amount);
    ERC20Mock(token_).transfer(msg.sender, _token_amount);
  }

  function exchange(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount)
    external
    override
  { }

  function exchange(
    uint256 from,
    uint256 to,
    uint256 _from_amount,
    uint256 _min_to_amount,
    bool use_eth
  ) external override { }

  function balances(uint256) external view override returns (uint256) {
    return 0;
  }

  function get_dy(int128 from, int128 to, uint256 _from_amount)
    external
    view
    override
    returns (uint256)
  { }

  function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
    external
    view
    override
    returns (uint256)
  { 
    return _amounts[0];
  }

  function calc_token_amount(uint256[] calldata _amounts, bool _is_deposit)
    external
    view
    override
    returns (uint256)
  { 
    return _amounts[0];
  }

  function calc_token_amount(
    address _pool,
    uint256[4] calldata _amounts,
    bool _is_deposit
  ) external view override returns (uint256) { 

    return _amounts[0];
  }

  function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit)
    external
    view
    override
    returns (uint256)
  { 

    return _amounts[0];
  }

  function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
    external
    view
    override
    returns (uint256)
  { 

    return _amounts[0];
  }

  function calc_withdraw_one_coin(uint256 amount, int128 i)
    external
    view
    override
    returns (uint256)
  { 
    return amount;
  }
}
