// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { TestBaseContract, console2 } from "./utils/TestBaseContract.sol";

contract LibBMPTest is TestBaseContract {
  function setUp() public virtual override {
    super.setUp();
  }

  function testGenerateBMP() public {

    diamond.setLockPermission(diamond.owner(), true);
    uint256 canvasId = diamond.createNewCanvas();
    assertEq(canvasId, 1, "Invalid canvas id");
  
    uint16[] memory colorIds = new uint16[](1);
    colorIds[0] = 1;
    uint16[] memory positions = new uint16[](1);
    positions[0] = 1;

    diamond.commitPixels(1, colorIds, positions);

    diamond.lockCanvas(1, "This is a test!");

  }
}