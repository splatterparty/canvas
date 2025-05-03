// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { AccessControl } from "../shared/AccessControl.sol";
import { TokenValidator } from "../shared/TokenValidator.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { IKongbucks } from "../interfaces/IKongbucks.sol";

import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import { IERC1155 } from "lib/solidstate-solidity/contracts/interfaces/IERC1155.sol";

contract AdminFacet is AccessControl, TokenValidator {    

    function setLockPermission(address account, bool permission) external isAdmin {
        LibAppStorage.diamondStorage().hasLockPermission[account] = permission;
    }

    function fixCanvasBlockData(uint256 tokenId, uint256 start, uint256 end) external isAdmin {
        LibAppStorage.diamondStorage().canvasBlocks[tokenId].start = start;
        LibAppStorage.diamondStorage().canvasBlocks[tokenId].end = end;
    }

    function setUnlockTimeNow(uint256 tokenId) external isAdmin {
        LibAppStorage.diamondStorage().canvasData[tokenId].lockTime = block.timestamp; //now!
    }

    function fixInterface() external isAdmin {
        LibDiamond.diamondStorage().supportedInterfaces[type(IERC1155).interfaceId] = true;
    }

    function fixMaxEditionSize() external isAdmin {
        for (uint256 tokenId = 1; tokenId <= 19; tokenId++) {
            LibAppStorage.diamondStorage().canvasMintProps[tokenId].editionMax = 1000;            
        }
    }

    function setKongbucksContract(address kongbucks) external isAdmin {
        LibAppStorage.diamondStorage().kongbucks = IKongbucks(kongbucks);
    }

}
