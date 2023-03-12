// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICurve3Pool { 

    function add_liquidity(uint256[3] calldata uamounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _amount, uint256[3] calldata min_uamounts) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;


    function is_killed() external view returns (bool);
    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amounts, int128 i) external view returns (uint256);
    function coins(int128 i) external view returns (address);
    function underlying_coins(int128 i) external view returns (address);
    function underlying_coins() external view returns (address[3] memory);
    function curve() external view returns (address);
    function token() external view returns (address);
}