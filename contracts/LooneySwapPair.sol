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

  function getReserves() public view returns (uint _reserve0, uint _reserve1) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
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
}
