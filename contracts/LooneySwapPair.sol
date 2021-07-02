//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./LooneySwapERC20.sol";

contract LooneySwapPair is LooneySwapERC20 {
  uint public constant INITIAL_SUPPLY = 10**5;

  using SafeMath for uint;

  address public token0;
  address public token1;

  uint public reserve0;
  uint public reserve1;

  constructor(address _token0, address _token1) LooneySwapERC20() {
    token0 = _token0;
    token1 = _token1;
  }

  function add(uint amount0, uint amount1) public {
    assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

    uint reserve0After = reserve0.add(amount0);
    uint reserve1After = reserve1.add(amount1);

    if (reserve0 == 0 && reserve1 == 0) {
      _mint(msg.sender, INITIAL_SUPPLY);
    } else {
      uint currentSupply = totalSupply();
      uint newSupplyGivenReserve0Ratio = reserve0After.mul(currentSupply).div(reserve0);
      uint newSupplyGivenReserve1Ratio = reserve1After.mul(currentSupply).div(reserve1);
      uint newSupply = Math.min(newSupplyGivenReserve0Ratio, newSupplyGivenReserve1Ratio);
      _mint(msg.sender, newSupply - currentSupply);
    }

    reserve0 = reserve0After;
    reserve1 = reserve1After;
  }

  function remove(uint liquidity) public {
    assert(transfer(address(this), liquidity));

    uint currentSupply = totalSupply();
    uint amount0 = liquidity.mul(reserve0).div(currentSupply);
    uint amount1 = liquidity.mul(reserve1).div(currentSupply);

    _burn(address(this), liquidity);
    assert(IERC20(token0).transfer(msg.sender, amount0));
    assert(IERC20(token1).transfer(msg.sender, amount1));

    reserve0 = reserve0.sub(amount0);
    reserve1 = reserve1.sub(amount1);
  }

  /**
   * X * Y = K
   */
  function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0.mul(reserve1);

    // x (reserve0) * y (reserve1) = k (constant)
    // (reserve0 + amountIn) * (reserve1 - amountOut) = k
    // (reserve1 - amountOut) = k / (reserve0 + amount)
    // newReserve1 = k / (newReserve0)
    // amountOut = newReserve1 - reserve1

    if (fromToken == token0) {
      newReserve0 = amountIn.add(reserve0);
      newReserve1 = k.div(newReserve0);
      amountOut = reserve1.sub(newReserve1);
    } else {
      newReserve1 = amountIn.add(reserve1);
      newReserve0 = k.div(newReserve1);
      amountOut = reserve0.sub(newReserve0);
    }

    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
  }

  function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
    require(fromToken == token0 || fromToken == token1, 'From token invalid');
    require(toToken == token0 || toToken == token1, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut, 'Slipped... on a banana');

    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut));

    reserve0 = newReserve0;
    reserve1 = newReserve1;
  }
}
