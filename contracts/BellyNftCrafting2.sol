// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRecipes.sol";
import "./BellyErrors.sol";

contract BellyNftCrafting2 is
  ERC1155,
  ERC1155Burnable,
  ERC1155Supply,
  ERC2981,
  AccessControl,
  Pausable,
  ReentrancyGuard
{
  event Crafted(
    address indexed sender,
    uint256 indexed recipeId,
    uint256[] ingredientIds,
    uint256[] ingredientAmounts
  );

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string public constant name = "Belly NFT";
  string public constant symbol = "BELLY";
  address public craftingContract;
  IRecipes public recipes;

  constructor() ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function craft(uint256) public payable virtual whenNotPaused {
    revert("Craft Contract Updated");
  }

  /*** The following functions are overrides required by Solidity ***/

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
