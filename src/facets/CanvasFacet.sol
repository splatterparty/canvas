// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { CanvasState, CanvasMintProps, CanvasContributions, CanvasBlocks } from "../shared/Structs.sol";
import { AccessControl } from "../shared/AccessControl.sol";
import { TokenValidator } from "../shared/TokenValidator.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibBMP } from "../libs/LibBMP.sol";
import { ERC1155EnumerableStorage } from "lib/solidstate-solidity/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import "../shared/SharedErrors.sol";

contract CanvasFacet is AccessControl, TokenValidator {
  string public constant VERSION = "0.1.5";

  function name() external pure returns (string memory) {
    return "Splatter Party Canvas";
  }

  function symbol() external pure returns (string memory) {
    return "CANVAS";
  }

  // the minimum amount of time before this canvas can be locked
  // and a new one can be created
  //uint256 public constant MINIMUM_UNLOCK_TIME = 24 hours; //MAINNET
  //uint256 public constant MINIMUM_UNLOCK_TIME = 1 minutes; //DEBUG
  uint256 public constant MINIMUM_UNLOCK_TIME = 0; //NO MINIMUM

  // canvas dimensions
  uint256 public constant CANVAS_WIDTH = 32;
  uint256 public constant CANVAS_HEIGHT = 32;

  // default minting properties
  uint256 public constant MAX_EDITION_SIZE = 1000;
  uint256 public constant MINT_COST = 1 ether;

  event CanvasCreated(uint256 tokenId);
  event CanvasUpdated(uint256 tokenId, uint16[] colorIds, uint16[] positions, address sender);
  event CanvasLocked(uint256 tokenId);

  function currentCanvasID() external view returns (uint256) {
    return LibAppStorage.diamondStorage().tokenIdCounter;
  }

  function getCanvasBlockInfo(
    uint256 tokenId
  ) external view isValidToken(tokenId) returns (uint256 start, uint256 end) {
    start = LibAppStorage.diamondStorage().canvasBlocks[tokenId].start;
    end = LibAppStorage.diamondStorage().canvasBlocks[tokenId].end;
  }

  function getCanvasData(
    uint256 tokenId
  )
    external
    view
    returns (
      uint256 lockTime,
      string memory title,
      bool locked,
      string memory lockedImage,
      uint256 editionSize,
      uint256 width,
      uint256 height
    )
  {
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];

    lockTime = state.lockTime;
    title = state.title;
    locked = state.isLocked;
    lockedImage = state.lockedImage;
    width = state.width;
    height = state.height;

    //CanvasMintProps storage mintProps = LibAppStorage.diamondStorage().canvasMintProps[tokenId];
    //editionSize = mintProps.editionSize;

    editionSize = ERC1155EnumerableStorage.layout().totalSupply[tokenId]; //here for compatibility
  }

  // anyone can create a new shared canvas
  // but only if the last canvas has been locked
  function createNewCanvas() external returns (uint256) {
    uint256 tokenId = LibAppStorage.diamondStorage().tokenIdCounter;
    //check that the last canvas is locked
    if (tokenId > 0) {
      CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];
      if (!state.isLocked) revert OnlyOneUnlockedCanvas(tokenId);
    }

    LibAppStorage.diamondStorage().tokenIdCounter++;

    //update the state
    uint256 currentId = LibAppStorage.diamondStorage().tokenIdCounter;
    CanvasState storage newState = LibAppStorage.diamondStorage().canvasData[currentId];
    newState.lockTime = block.timestamp + MINIMUM_UNLOCK_TIME;
    newState.width = uint16(CANVAS_WIDTH);
    newState.height = uint16(CANVAS_HEIGHT);
    newState.pixels = new uint16[](CANVAS_WIDTH * CANVAS_HEIGHT);

    CanvasMintProps storage mintProps = LibAppStorage.diamondStorage().canvasMintProps[currentId];
    mintProps.editionMax = MAX_EDITION_SIZE;
    mintProps.mintCost = MINT_COST;

    CanvasBlocks storage blocks = LibAppStorage.diamondStorage().canvasBlocks[currentId];
    blocks.start = block.number;

    emit CanvasCreated(currentId);

    return currentId;
  }

  //function createCustomCanvas(uint16 width, uint16 height) external returns (uint256) {
  //}

  function getPixels(
    uint256 tokenId
  ) external view isValidToken(tokenId) returns (uint16[] memory) {
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];
    return state.pixels;
  }

  function getContributors(
    uint256 tokenId
  )
    external
    view
    isValidToken(tokenId)
    returns (address[] memory contributors, uint256[] memory pixelCount)
  {
    CanvasContributions storage contributionState = LibAppStorage
      .diamondStorage()
      .canvasContributions[tokenId];
    contributors = contributionState.contributors;
    pixelCount = new uint256[](contributors.length);
    for (uint256 i = 0; i < contributors.length; i++) {
      pixelCount[i] = contributionState.contributions[contributors[i]];
    }
  }

  function getLockTime(uint256 tokenId) external view isValidToken(tokenId) returns (uint256) {
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];
    return state.lockTime;
  }

  function commitPixels(
    uint256 tokenId,
    uint16[] calldata colorIds,
    uint16[] calldata positions
  ) external isValidToken(tokenId) {
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];

    //check that the canvas is not locked
    if (state.isLocked) revert CanvasIsLocked(tokenId);

    uint256 maxPixels = uint256(state.width) * uint256(state.height);

    for (uint256 i = 0; i < colorIds.length; i++) {
      uint16 colorId = colorIds[i];
      uint16 offset = positions[i];

      //check that the pixel is in bounds
      if (offset >= maxPixels) revert InvalidPixelOffset(offset);

      state.pixels[offset] = colorId;
    }

    //record the contribution
    CanvasContributions storage contributionState = LibAppStorage
      .diamondStorage()
      .canvasContributions[tokenId];

    if (contributionState.contributions[msg.sender] == 0)
      contributionState.contributors.push(msg.sender);
    contributionState.contributions[msg.sender] += colorIds.length;

    emit CanvasUpdated(tokenId, colorIds, positions, msg.sender);
  }

  function hasLockPermission(address user, uint256 /*tokenId*/) external view returns (bool) {
    //TODO: per token lock permissions?
    return LibAppStorage.diamondStorage().hasLockPermission[user];
  }

  // lock the canvas so that it can't be updated
  // - whoever locks the canvas will be the new owner and be able to set the title
  // - the canvas can only be locked once
  function lockCanvas(uint256 tokenId, string calldata title) external isValidToken(tokenId) {
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];
    //check that the canvas is not already locked
    if (state.isLocked) revert CanvasIsLocked(tokenId);

    //check that the minimum time has passed
    //if (block.timestamp < state.lockTime) revert NotReadyToLock(tokenId);

    bool hasPermission = LibAppStorage.diamondStorage().hasLockPermission[msg.sender];

    if (!hasPermission) revert NeedLockPermission(msg.sender);

    // need to contribute at least once to be able to lock it
    //CanvasContributions storage contributionState = LibAppStorage.diamondStorage().canvasContributions[tokenId];
    //if (contributionState.contributions[msg.sender] == 0)
    //	revert NeedToContributeFirst(tokenId);

    //lock the canvas
    state.isLocked = true;

    //update the lock time to reflect when the canvas was locked
    state.lockTime = block.timestamp;

    //set the title
    state.title = title;

    state.lockedImage = LibBMP.generateBMP(state.width, state.height, state.pixels);

    CanvasBlocks storage blocks = LibAppStorage.diamondStorage().canvasBlocks[tokenId];
    blocks.end = block.number;

    emit CanvasLocked(tokenId);
  }

  //withdraw funds
  function withdraw() external isAdmin {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function nextTokenIdToMint() external view returns (uint256) {
    return LibAppStorage.diamondStorage().tokenIdCounter + 1;
  }
}
