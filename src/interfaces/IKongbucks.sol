// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IERC20 } from "lib/solidstate-solidity/contracts/interfaces/IERC20.sol";

interface IKongbucks is IERC20 {
  function priceToMint(uint256 amount) external view returns (uint256);
}