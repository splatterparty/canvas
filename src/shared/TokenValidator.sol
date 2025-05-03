// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibAppStorage } from "../libs/LibAppStorage.sol";

error InvalidTokenID(uint256 tokenID);

abstract contract TokenValidator {
    modifier isValidToken(uint256 tokenID) {
        if (tokenID == 0 || tokenID > LibAppStorage.diamondStorage().tokenIdCounter) revert InvalidTokenID(tokenID);
        _;
    }    
}
