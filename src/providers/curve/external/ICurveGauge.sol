// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface ICurveMinter {
    function mint(address gauge_addr) external;
    function minted(address _for, address gauge_addr) external view returns(uint256);

    function toggle_approve_mint(address minting_user) external;
    function token() external view returns(address);
}

interface ICurveGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function claim_rewards() external;

    function claimable_tokens(address) external view returns (uint256);

    function claimable_reward(address _addressToCheck, address _rewardToken)
        external
        view
        returns (uint256);

    function withdraw(uint256) external;

    function reward_tokens(uint256) external view returns (address); //v2

    function rewarded_token() external view returns (address); //v1

    function lp_token() external view returns (address);
}
