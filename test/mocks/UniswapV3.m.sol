pragma solidity ^0.8.4;

abstract contract UniswapV3Pool {
    // Called after every swap showing the new uniswap price for this token pair.
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );
    // Base currency.

    address public token0;
    // Quote currency.
    address public token1;
}

contract UniswapV3Mock is UniswapV3Pool {
    function setTokens(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }

    function setPrice(
        address sender,
        address recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    ) external {
        emit Swap(sender, recipient, amount0, amount1, sqrtPriceX96, liquidity, tick);
    }
}
