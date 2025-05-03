// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct MetaTxContextStorage {
  address trustedForwarder;
}

struct CanvasState {  
  uint256 lockTime; // if !isLocked, represents when canvas can be locked, else represents when the canvas was locked
  bool isLocked;
  uint16 version;
  uint16 width;
  uint16 height;
  string title;
  string lockedImage; // set after locking
  uint16[] pixels;
}

struct CanvasContributions
{
  mapping(address => uint256) contributions;
  address[] contributors;
}

struct CanvasMintProps {
  //minting props 
  uint256 mintCost;
  uint256 editionSize;  //deprecated - use totalSize instead
  uint256 editionMax;   //maximum mints allowed
}

struct CanvasPermissions {
  //per-canvas access control
  address owner;
  mapping(address => uint256) whitelist;
  mapping(address => uint256) blacklist;
}

struct CanvasBlocks {
  uint256 start;
  uint256 end;
}

struct CanvasTitleSuggestion
{  
  string suggestedTitle;
  address suggestedBy;
  uint256 votes;  
}