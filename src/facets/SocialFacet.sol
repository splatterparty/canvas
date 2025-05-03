pragma solidity >=0.8.21;

import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { TokenValidator } from "../shared/TokenValidator.sol";
import { IKongClub } from "../interfaces/IKongClub.sol";
import "../shared/Structs.sol";
import "../shared/SharedErrors.sol";


contract SocialFacet is TokenValidator {

    uint256 public constant MAX_TITLE_SUGGESTION_VOTES = 10;

    function suggestTitle(uint256 tokenId, string memory name) external isValidToken(tokenId) {
        
        CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];

        //check that this is not locked yet                
        if (state.isLocked) revert CanvasIsLocked(tokenId);

        //check that the sender owns a kongclub
        if (IKongClub(LibConstants.KONGCLUB).balanceOf(msg.sender) == 0) revert NoKeycard(msg.sender);

        //check that the suggested name is greater then 3 characters long
        if (bytes(name).length < 3) revert SuggestedTitleTooShort(name);

        //check that the member has not already suggested a title
        if (LibAppStorage.diamondStorage().hasMemberSuggestedTitle[tokenId][msg.sender])
        {
            uint256 memberSuggestionIdx = LibAppStorage.diamondStorage().memberSuggestedTitleIndex[tokenId][msg.sender];
            CanvasTitleSuggestion memory memberSuggestion = LibAppStorage.diamondStorage().suggestedTitles[tokenId][memberSuggestionIdx];
            revert MemberAlreadySuggested(tokenId, msg.sender, memberSuggestion.suggestedTitle);
        }
                
        uint256 idx = LibAppStorage.diamondStorage().suggestedTitles[tokenId].length;
        LibAppStorage.diamondStorage().memberSuggestedTitleIndex[tokenId][msg.sender] = idx;
        LibAppStorage.diamondStorage().hasMemberSuggestedTitle[tokenId][msg.sender] = true;

        LibAppStorage.diamondStorage().suggestedTitles[tokenId].push(CanvasTitleSuggestion({suggestedBy: msg.sender, suggestedTitle: name, votes: 0}));

    }

    function voteForTitle(uint256 tokenId, uint256[] calldata votes) external isValidToken(tokenId) {

        CanvasState storage state = LibAppStorage.diamondStorage().canvasData[tokenId];

        //check that this is not locked yet                
        if (state.isLocked) revert CanvasIsLocked(tokenId);

        //check that the sender owns a kongclub
        if (IKongClub(LibConstants.KONGCLUB).balanceOf(msg.sender) == 0) revert NoKeycard(msg.sender);

        //go through each vote
        for (uint256 i = 0; i < votes.length; i++) {

            if ( LibAppStorage.diamondStorage().memberSuggestedVotes[tokenId][msg.sender] >= MAX_TITLE_SUGGESTION_VOTES) 
                revert MaxTitleSuggestionVotesExceeded(tokenId, msg.sender);

            if (votes[i] >= LibAppStorage.diamondStorage().suggestedTitles[tokenId].length)
                revert InvalidTitleSuggestionId(tokenId, votes[i]);

            CanvasTitleSuggestion storage memberSuggestion = LibAppStorage.diamondStorage().suggestedTitles[tokenId][votes[i]];            
            memberSuggestion.votes++;
            LibAppStorage.diamondStorage().memberSuggestedVotes[tokenId][msg.sender]++;
        }
    }
    

    function getNumSuggestedTitles(uint256 tokenId) external view isValidToken(tokenId) returns (uint256) {
        return LibAppStorage.diamondStorage().suggestedTitles[tokenId].length;
    }

    function hasMemberSuggestedTitle(uint256 tokenId, address member) external view isValidToken(tokenId) returns (bool) {
        
        if (IKongClub(LibConstants.KONGCLUB).balanceOf(member) == 0) revert NoKeycard(member);

        return LibAppStorage.diamondStorage().hasMemberSuggestedTitle[tokenId][member];
    }

    function getMemberSuggestedTitleId(uint256 tokenId, address member) external view isValidToken(tokenId) returns (uint256) {
        
        if (IKongClub(LibConstants.KONGCLUB).balanceOf(member) == 0) revert NoKeycard(member);

        if (!LibAppStorage.diamondStorage().hasMemberSuggestedTitle[tokenId][member])
            revert NoMemberSuggestion(tokenId, member);

        return LibAppStorage.diamondStorage().memberSuggestedTitleIndex[tokenId][member];
    }

    function getSuggestedTitle(uint256 tokenId, uint256 idx) external view isValidToken(tokenId) returns (CanvasTitleSuggestion memory) {
        if (idx >= LibAppStorage.diamondStorage().suggestedTitles[tokenId].length) 
            revert InvalidTitleSuggestionId(tokenId, idx);
        return LibAppStorage.diamondStorage().suggestedTitles[tokenId][idx];
    }

    function getSuggestedTitleVotesRemaining(uint256 tokenId, address member) external view isValidToken(tokenId) returns (uint256) {
        
        if (IKongClub(LibConstants.KONGCLUB).balanceOf(member) == 0) revert NoKeycard(member);

        return MAX_TITLE_SUGGESTION_VOTES - LibAppStorage.diamondStorage().memberSuggestedVotes[tokenId][member];
    }

}