// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibAppStorage } from "./LibAppStorage.sol";
import { IKongbucks } from "../interfaces/IKongbucks.sol";

library LibKongbucks {

    error InsufficientKongbucks();

    function kongbucks() internal view returns (IKongbucks) {
        return LibAppStorage.diamondStorage().kongbucks;
    }

    function balanceOf(address owner) internal view returns (uint256) {
        return LibAppStorage.diamondStorage().kongbucks.balanceOf(owner);
    }

    function checkBalance(address owner, uint256 amount) internal view {
        if (LibAppStorage.diamondStorage().kongbucks.balanceOf(owner) < amount) 
            revert InsufficientKongbucks();
    }

    function transfer(address from, address to, uint256 amount) internal {
        LibAppStorage.diamondStorage().kongbucks.transferFrom(from, to, amount);
    }

}