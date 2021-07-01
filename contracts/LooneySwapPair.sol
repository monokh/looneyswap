//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./LooneySwapERC20.sol";

contract LooneySwapPair is LooneySwapERC20 {
  using SafeMath for uint256;

  address public token0;
  address public token1;

  uint256 public reserve0;
  uint256 public reserve1;

  constructor(address _token0, address _token1) LooneySwapERC20() {
    token0 = _token0;
    token1 = _token1;
  }

  function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
  }

  function add(uint256 token0Amount, uint256 token1Amount) public {
    assert(IERC20(token0).transferFrom(msg.sender, address(this), token0Amount));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), token1Amount));

    reserve0 = reserve0.add(token0Amount);
    reserve1 = reserve1.add(token1Amount);
  }
}
