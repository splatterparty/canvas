// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

error CanvasIsLocked(uint256 tokenId);
error NotReadyToLock(uint256 tokenId);
error NeedLockPermission(address account);
error ColorNotOwnedByAddress(uint256 color, address owner);
error InvalidPixelOffset(uint16 offset);
error OnlyOneUnlockedCanvas(uint256 tokenId);

//error NeedToContributeFirst(uint256 tokenId);

error NoKeycard(address account);
error SuggestedTitleTooShort(string title);
error MemberAlreadySuggested(uint256 tokenId, address member, string suggestion);
error InvalidTitleSuggestionId(uint256 tokenId, uint256 id);
error MaxTitleSuggestionVotesExceeded(uint256 tokenId, address member);
error NoMemberSuggestion(uint256 tokenId, address member);

