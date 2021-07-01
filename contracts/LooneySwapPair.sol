//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract LooneySwapPair {
  address public token0;
  address public token1;

  uint256 public reserve0;
  uint256 public reserve1;

  constructor(address _token0, address _token1) {
    token0 = _token0;
    token1 = _token1;
  }

  function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
  }
}
