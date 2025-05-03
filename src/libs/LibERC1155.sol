// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { CanvasState } from "../shared/Structs.sol";

import { Base64 } from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

library LibERC1155 {

    using Strings for uint256;

    string private constant lockedTokenURI = "ipfs://QmdGou6abaRtYAnN2oqoF9K4WurAb8rS7FymwAepFiqch2";

    function uri( uint256 tokenID) internal view returns (string memory) 
    {
        //get the canvas state
        CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenID];

        if (state.isLocked) {

        //string memory imgTag = '", "image": "data:image/bmp;base64,'; //this is technically "correct", but makes it look blurry on the HUB
        string memory imgTag;
                
        //old way
        if (tokenID <= 8) {
            imgTag = string(abi.encodePacked('", "image": "data:image/svg+xml;utf8,',
            state.lockedImage
            ));
        } 
        else
        {
            imgTag = string(abi.encodePacked('", "image": "data:image/svg+xml;utf8,', "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 256 256'> <image width='256' height='256' style='image-rendering:pixelated' href='data:image/bmp;base64,",
            state.lockedImage,
            "'/></svg>" //close SVG
            ));
        }

        //create the metadata string
        // see https://docs.opensea.io/docs/metadata-standards
        string memory json = Base64.encode(
            bytes(
            string(
                abi.encodePacked(
                '{ "name": "',
                state.title,
                '", "description": "Splatter Party #',
                tokenID.toString(),
                '", "external_url": "https://splatterparty.xyz/',
                tokenID.toString(),
                imgTag,              
                '", "creator": { "name": "0x8880b4De2d17d400f6dd25Ea2DFdb5B6d0c3A888", "link": "https://subnets.avax.network/lamina1/address/0x8880b4De2d17d400f6dd25Ea2DFdb5B6d0c3A888"}, "tags":["Pixels", "Community", "Fun"] }'
                )
            )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));

        }

    return lockedTokenURI;
    }

}