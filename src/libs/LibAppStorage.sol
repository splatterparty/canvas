// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { IKongbucks } from "../interfaces/IKongbucks.sol";

struct AppStorage {
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;

    /*
    TODO: Customize storage variables here

    NOTE: Once contracts have been deployed you cannot modify the existing entries here. You can only append 
    new entries. Otherwise, any subsequent upgrades you perform will break the memory structure of your 
    deployed contracts.
    */

    uint256 tokenIdCounter;

    mapping(uint256 => CanvasState) canvasData;

    mapping(uint256 => CanvasContributions) canvasContributions;

    mapping(uint256 => CanvasMintProps) canvasMintProps;

    mapping(uint256 => CanvasPermissions) canvasPermissions;

    //keep track of block numbers for grabbing logs in a range
    mapping(uint256 => CanvasBlocks) canvasBlocks;

    //list of users that have permission to lock the canvas
    mapping(address => bool) hasLockPermission;

    //suggested titles
    mapping (uint256 => uint256) not_used;
    mapping(uint256 => CanvasTitleSuggestion[]) suggestedTitles;
    mapping(uint256 => mapping(address => uint256)) memberSuggestedTitleIndex;
    mapping(uint256 => mapping(address => uint256)) memberSuggestedVotes;
    mapping(uint256 => mapping(address => bool)) hasMemberSuggestedTitle;

    IKongbucks kongbucks;

}

library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
