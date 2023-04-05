pragma solidity ^0.8.4;

import {ERC20} from "../../../src/periphery/ERC20.sol";

import {ERC20Mock, WERC20Mock} from "../../mocks/ERC20.m.sol";
import {IPool} from "../../../src/providers/aaveV3/external/IPool.sol";

contract PoolMock is IPool {
    mapping(address => address) internal reserveAToken;

    function setReserveAToken(address _reserve, WERC20Mock aToken) external {
        reserveAToken[_reserve] = address(aToken);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external override {
        // Transfer asset
        ERC20 token = ERC20(asset);
        address aTokenAddress = reserveAToken[asset];
        token.transferFrom(msg.sender, address(this), amount);

        // Mint aTokens
        WERC20Mock aToken = WERC20Mock(aTokenAddress);
        token.increaseAllowance(aTokenAddress, amount);
        aToken.wrap(amount);
        aToken.transfer(msg.sender, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external override returns (uint256) {
        // Burn aTokens
        address aTokenAddress = reserveAToken[asset];
        WERC20Mock aToken = WERC20Mock(aTokenAddress);
        aToken.transferFrom(msg.sender, address(this), amount);
        aToken.unwrap(amount);

        // Transfer asset
        ERC20 token = ERC20(asset);
        token.transfer(to, amount);
        return amount;
    }

    function getReserveData(address asset) external view override returns (IPool.ReserveData memory data) {
        /// active pool Aave V3 config
        data.configuration = ReserveConfigurationMap(379853412004453730017650325597649023837875453566284);
        data.aTokenAddress = reserveAToken[asset];
    }
}
