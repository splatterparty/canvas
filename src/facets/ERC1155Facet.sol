// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";

import { ISolidStateERC1155 } from "lib/solidstate-solidity/contracts/token/ERC1155/ISolidStateERC1155.sol";
import { ERC1155BaseInternal } from "lib/solidstate-solidity/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155MetadataInternal } from "lib/solidstate-solidity/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { ERC1155EnumerableInternal } from "lib/solidstate-solidity/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import { ERC1155BaseStorage } from "lib/solidstate-solidity/contracts/token/ERC1155/base/ERC1155BaseStorage.sol";

import { IERC165 } from "lib/solidstate-solidity/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "lib/solidstate-solidity/contracts/interfaces/IERC1155.sol";
import { IERC1155Enumerable } from "lib/solidstate-solidity/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";

import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { Base64 } from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import { CanvasState, CanvasMintProps } from "../shared/Structs.sol";
import { TokenValidator } from "../shared/TokenValidator.sol";

import { IKongbucks } from "../interfaces/IKongbucks.sol";

import { LibERC1155 } from "../libs/LibERC1155.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibKongbucks } from "../libs/LibKongbucks.sol";

error CantMintUntilLocked(uint256 tokenID);
error MaxEditionSizeReached(uint256 tokenID);
error InsufficientFunds(uint256 required, uint256 provided);

contract ERC1155Facet is
  ISolidStateERC1155,
  ERC1155BaseInternal,
  ERC1155EnumerableInternal,
  ERC1155MetadataInternal,
  TokenValidator
{
  using Strings for uint256;

  event CanvasMinted();

  function kongbucksAddress() external view returns (address) {
    return address(LibKongbucks.kongbucks());
  }

  function _getMintWithKongbucksCost(uint256 /*id*/) internal pure returns (uint256) {
    return LibConstants.KONGBUCKS_COST; //just use a flat rate for now
  }

  function getMintWithKongbucksCost(uint256 id) external pure returns (uint256) {
    return _getMintWithKongbucksCost(id);
  }

  function mintWithKongbucks(address account, uint256 id) external isValidToken(id) {
    //ensure that it is locked
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[id];
    if (!state.isLocked) revert CantMintUntilLocked(id);

    CanvasMintProps storage mintProps = LibAppStorage.diamondStorage().canvasMintProps[id];

    //check supply for this token
    if (_totalSupply(id) + 1 > mintProps.editionMax) revert MaxEditionSizeReached(id);

    //get price to purchase with kongbucks
    uint256 cost = _getMintWithKongbucksCost(id);

    //check that the sender has enough kongbucks
    uint256 kongbucksBalance = LibKongbucks.balanceOf(msg.sender);

    if (kongbucksBalance < cost) revert InsufficientFunds(cost, kongbucksBalance);

    //note: this contract has auto approval set up in the kongBucks contract

    LibKongbucks.transfer(msg.sender, LibDiamond.contractOwner(), cost);

    //increment the supply
    //mintProps.editionSize = mintProps.editionSize + 1;

    _mint(account, id, 1, "");

    emit CanvasMinted();
  }

  function batchMintWithKongbucks(
    address account,
    uint256 id,
    uint256 amount
  ) external isValidToken(id) {
    //ensure that it is locked
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[id];
    if (!state.isLocked) revert CantMintUntilLocked(id);

    CanvasMintProps storage mintProps = LibAppStorage.diamondStorage().canvasMintProps[id];

    //check supply for this token
    if (_totalSupply(id) + amount > mintProps.editionMax) revert MaxEditionSizeReached(id);

    //get price to purchase with kongbucks
    uint256 cost = _getMintWithKongbucksCost(id) * amount;

    //check that the sender has enough kongbucks
    uint256 kongbucksBalance = LibKongbucks.balanceOf(msg.sender);
    if (kongbucksBalance < cost) revert InsufficientFunds(cost, kongbucksBalance);

    //note: this contract has auto approval set up in the kongBucks contract

    LibKongbucks.transfer(msg.sender, LibDiamond.contractOwner(), cost);

    //increment the supply
    //mintProps.editionSize = mintProps.editionSize + amount;

    _mint(account, id, amount, "");

    emit CanvasMinted();
  }

  function mint(address account, uint256 id) external payable isValidToken(id) {
    //ensure that it is locked
    CanvasState storage state = LibAppStorage.diamondStorage().canvasData[id];
    if (!state.isLocked) revert CantMintUntilLocked(id);

    CanvasMintProps storage mintProps = LibAppStorage.diamondStorage().canvasMintProps[id];

    //check supply for this token
    if (_totalSupply(id) + 1 > mintProps.editionMax) revert MaxEditionSizeReached(id);

    //check the payable amount
    if (msg.value < mintProps.mintCost) revert InsufficientFunds(mintProps.mintCost, msg.value);

    //increment the supply
    //mintProps.editionSize = mintProps.editionSize + 1;

    _mint(account, id, 1, "");

    emit CanvasMinted();
  }

  //get the metadata for a canvas //overrides IERC1155MetadataURI
  function uri(
    uint256 tokenID
  ) external view override isValidToken(tokenID) returns (string memory) {
    return LibERC1155.uri(tokenID);
  }

  // Since SolidStateERC1155 implements IERC165 their own way, we need to implement it here
  // the same as DiamondLoupeFacet so our diamond doesn't break if this method is replaced
  // (ERC1155Base <- IERC1155Base <- IERC1155 <- IERC165)
  function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    return ds.supportedInterfaces[_interfaceId];
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155BaseInternal, ERC1155EnumerableInternal) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // lib/solidstate-solidity/contracts/token/ERC1155/base/ERC1155Base.sol

  /**
   * @inheritdoc IERC1155
   */
  function balanceOf(address account, uint256 id) external view returns (uint256) {
    return _balanceOf(account, id);
  }

  /**
   * @inheritdoc IERC1155
   */
  function balanceOfBatch(
    address[] memory accounts,
    uint256[] memory ids
  ) external view returns (uint256[] memory) {
    if (accounts.length != ids.length) revert ERC1155Base__ArrayLengthMismatch();

    mapping(uint256 => mapping(address => uint256)) storage balances = ERC1155BaseStorage
      .layout()
      .balances;

    uint256[] memory batchBalances = new uint256[](accounts.length);

    unchecked {
      for (uint256 i; i < accounts.length; i++) {
        if (accounts[i] == address(0)) revert ERC1155Base__BalanceQueryZeroAddress();
        batchBalances[i] = balances[ids[i]][accounts[i]];
      }
    }

    return batchBalances;
  }

  /**
   * @inheritdoc IERC1155
   */
  function isApprovedForAll(address account, address operator) external view returns (bool) {
    return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
  }

  /**
   * @inheritdoc IERC1155
   */
  function setApprovalForAll(address operator, bool status) external {
    if (msg.sender == operator) revert ERC1155Base__SelfApproval();
    ERC1155BaseStorage.layout().operatorApprovals[msg.sender][operator] = status;
    emit ApprovalForAll(msg.sender, operator, status);
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external {
    if (from != msg.sender && !ERC1155BaseStorage.layout().operatorApprovals[from][msg.sender])
      revert ERC1155Base__NotOwnerOrApproved();
    _safeTransfer(msg.sender, from, to, id, amount, data);
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external {
    if (from != msg.sender && !ERC1155BaseStorage.layout().operatorApprovals[from][msg.sender])
      revert ERC1155Base__NotOwnerOrApproved();
    _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
  }

  // lib/solidstate-solidity/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol

  /**
   * @inheritdoc IERC1155Enumerable
   */
  function totalSupply(uint256 id) external view returns (uint256) {
    return _totalSupply(id);
  }

  /**
   * @inheritdoc IERC1155Enumerable
   */
  function totalHolders(uint256 id) external view returns (uint256) {
    return _totalHolders(id);
  }

  /**
   * @inheritdoc IERC1155Enumerable
   */
  function accountsByToken(uint256 id) external view returns (address[] memory) {
    return _accountsByToken(id);
  }

  /**
   * @inheritdoc IERC1155Enumerable
   */
  function tokensByAccount(address account) external view returns (uint256[] memory) {
    return _tokensByAccount(account);
  }


  // added this to fix busted metadata:

  function refreshMetadata(uint256 tokenId) external {
      emit URI(LibERC1155.uri(tokenId), tokenId);
  }

  function refreshMetadataBatch(uint256 fromTokenId, uint256 toTokenId) external {
      for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
          emit URI(LibERC1155.uri(tokenId), tokenId);
      }
  }

}
