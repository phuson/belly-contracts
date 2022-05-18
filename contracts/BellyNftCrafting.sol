// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRecipes.sol";
import "./BellyErrors.sol";

/// @title Contains the implementation detail of the crafting functionality
/// for the main BellyNft contract (via the Delegate Proxy Pattern).
/// Therefore, all of the NFT details are left as blanks
/// to reserve the contract's storage space so they cannot be overriden accidentally.
contract BellyNftCrafting is
  ERC1155,
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
  string public constant name = "";
  string public constant symbol = "";
  address public craftingContract;
  IRecipes public recipes;

  constructor() ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Craft/Mint a new recipe NFT to the crafter (msg.sender)
  /// @dev This function will look up to see if user has the required NFTs needed.
  ///      It burns the required set of ingredient NFTs and mint a new recipe NFT.
  /// @param recipeId The recipe NFT ID to be crafted.
  function craft(uint256 recipeId) external payable virtual whenNotPaused {
    // get requirements from recipe contract
    (
      uint256 resultTokenId,
      uint256[] memory requiredTokenIds,
      uint256[] memory requiredAmounts
    ) = recipes.getRecipe(recipeId);

    // compile the array of addresses for the batch call
    uint256 idsLength = requiredTokenIds.length;
    address[] memory addresses = new address[](idsLength);
    for (uint256 i = 0; i < idsLength; i++) {
      addresses[i] = msg.sender;
    }

    // check balances of tokens for user
    uint256[] memory balances = balanceOfBatch(addresses, requiredTokenIds);

    for (uint256 i = 0; i < idsLength; i++) {
      if (balances[i] < requiredAmounts[i]) {
        revert InsufficientTokenBalance();
      }
    }

    // burn ingredient tokens
    _burnBatch(msg.sender, requiredTokenIds, requiredAmounts);

    // mint new token and send to user
    _mint(msg.sender, resultTokenId, 1, "");

    emit Crafted(msg.sender, recipeId, requiredTokenIds, requiredAmounts);
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
