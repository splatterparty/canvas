// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Base64 } from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

library LibBMP {

    function generateBMP(uint256 width, uint256 height, uint16[] storage pixelData) internal view returns (string memory) {

		uint32 rawDataSize = uint32(width * height * 3);
		uint32 bmpSize = rawDataSize + 54;

		//encode the BMP
		bytes memory bmpBytes = new bytes(bmpSize);

        assembly {
			let memPtr := add(bmpBytes, 32) // Skip the length field in the bytes array
		    // ===== bmp header =====
		    mstore8(memPtr, 0x42)           //B
			mstore8(add(memPtr, 1), 0x4D)   //M
		    // ===== total file size	
		    mstore8(add(memPtr, 2), and(bmpSize, 0xFF))      
			mstore8(add(memPtr, 3), and(shr(8, bmpSize), 0xFF))
            mstore8(add(memPtr, 4), and(shr(16, bmpSize), 0xFF))
            mstore8(add(memPtr, 5), and(shr(24, bmpSize), 0xFF))
            // ===== reserved =====
            //bmpBytes[6] = 0x00;
            //bmpBytes[7] = 0x00;
            //bmpBytes[8] = 0x00;
            //bmpBytes[9] = 0x00;
            // ===== offset to pixel data -> 54 bytes (14+40) (0x36)
            mstore8(add(memPtr, 10), 0x36)
            //bmpBytes[11] = 0x00;
            //bmpBytes[12] = 0x00;
            //bmpBytes[13] = 0x00;
            // ===== DIB header size (40 bytes) (0x28)
            mstore8(add(memPtr, 14), 0x28)
            //bmpBytes[15] = 0x00;
            //bmpBytes[16] = 0x00;
            //bmpBytes[17] = 0x00;
            // ===== width
            mstore8(add(memPtr, 18), and(width, 0xFF))
			mstore8(add(memPtr, 19), and(shr(8, width), 0xFF))
			mstore8(add(memPtr, 20), and(shr(16, width), 0xFF))
			mstore8(add(memPtr, 21), and(shr(24, width), 0xFF))
            // ===== height
            mstore8(add(memPtr, 22), and(height, 0xFF))
			mstore8(add(memPtr, 23), and(shr(8, height), 0xFF))
			mstore8(add(memPtr, 24), and(shr(16, height), 0xFF))
			mstore8(add(memPtr, 25), and(shr(24, height), 0xFF))
            // ===== color planes (1) =====
            mstore8(add(memPtr, 26), 0x01)
            //bmpBytes[27] = 0x00;
            // bits per pixel (24) (0x18)
            mstore8(add(memPtr, 28), 0x18)
            //bmpBytes[29] = 0x00;
            // ===== compression
            //bmpBytes[30] = 0x00;
            //bmpBytes[31] = 0x00;
            //bmpBytes[32] = 0x00;
            //bmpBytes[33] = 0x00;
            // ===== size of raw bitmap data (including padding)
            mstore8(add(memPtr, 34), and(rawDataSize, 0xFF))
			mstore8(add(memPtr, 35), and(shr(8, rawDataSize), 0xFF))
            mstore8(add(memPtr, 36), and(shr(16, rawDataSize), 0xFF))
            mstore8(add(memPtr, 37), and(shr(24, rawDataSize), 0xFF))
            // ===== horizontal resolution 72 DPI (0x130B)
            mstore8(add(memPtr, 38), 0x13)
            mstore8(add(memPtr, 39), 0x0B)
            //bmpBytes[40] = 0x00;
            //bmpBytes[41] = 0x00;
            // ===== vertical resolution 72 DPI (0x130B)
            mstore8(add(memPtr, 42), 0x13)
            mstore8(add(memPtr, 43), 0x0B)
            //bmpBytes[44] = 0x00;
            //bmpBytes[45] = 0x00;
            // ===== colors in palette
            //bmpBytes[46] = 0x00;
            //bmpBytes[47] = 0x00;
            //bmpBytes[48] = 0x00;
            //bmpBytes[49] = 0x00;
            // ===== important colors
            //bmpBytes[50] = 0x00;
            //bmpBytes[51] = 0x00;
            //bmpBytes[52] = 0x00;
            //bmpBytes[53] = 0x00;
        }

		// ----- copy the color bytes into the bmp 
		// the colors are 4bit per channel, so we need to convert to 8bit by multiplying by 17 or (x << 4) | x
		// need to flip the y axis for bmp

		for (uint256 y = 0; y < height; y++) {
			for (uint256 x = 0; x < width; x++) {
				uint256 i = (height - y - 1) * width + x;
				uint256 offset = i * 3 + 54;
				uint16 colorVal = pixelData[y * width + x];
				bmpBytes[offset] = bytes1(uint8(colorVal & 0xf) * 17);
				bmpBytes[offset+1] = bytes1(uint8((colorVal >> 4) & 0xf) * 17);
				bmpBytes[offset+2] = bytes1(uint8((colorVal >> 8) & 0xf) * 17);
			}
		}

		return Base64.encode(bmpBytes);
	}

}
