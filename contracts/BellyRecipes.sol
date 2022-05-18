// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IRecipes.sol";
import "./BellyErrors.sol";

interface IBellyNft is IERC1155 {
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

/// @title Contract that contains the list of recipes on-chain
/// Each recipe takes in a set of token by their IDs and produces an recipe NFT as a result
contract BellyRecipes is AccessControl, IRecipes {
  event RecipeAdded(uint256 indexed recipeId);
  event RecipeRemoved(uint256 indexed recipeId);

  struct Recipe {
    uint256[] tokenIds;
    uint256[] amounts;
  }

  mapping(uint256 => Recipe) private _recipes;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Add new recipe to the on-chain array
  /// @dev Admin Only
  /// @param recipeId The Recipe NFT ID. This ID is the result token ID that is minted when this recipe is crafted.
  /// @param tokenIds Array of NFT IDs that are required to craft this recipe
  /// @param amounts Array of amounts for each NFT ID that are needed to craft this recipe
  function addRecipe(
    uint256 recipeId,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    returns (
      uint256 id,
      uint256[] memory ids,
      uint256[] memory amts
    )
  {
    if (recipeExists(recipeId)) {
      revert RecipeIdAlreadyExists();
    }

    if (tokenIds.length == 0 || amounts.length == 0) {
      revert EmptyInputs();
    }
    if (tokenIds.length != amounts.length) {
      revert MismatchInputs();
    }

    _recipes[recipeId].tokenIds = tokenIds;
    _recipes[recipeId].amounts = amounts;

    emit RecipeAdded(recipeId);

    return (recipeId, tokenIds, amounts);
  }

  /// @notice Remove existing recipe from the on-chain array
  /// @dev Admin Only
  /// @param recipeId The Recipe ID to be removed from the on-chain array
  function removeRecipe(uint256 recipeId)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (!recipeExists(recipeId)) {
      revert RecipeDoesNotExist();
    }

    delete _recipes[recipeId];

    emit RecipeRemoved(recipeId);
  }

  /// @notice Get recipe by given ID from the on-chain array
  /// @param recipeId The Recipe ID to retrieve
  function getRecipe(uint256 recipeId)
    external
    view
    hasRecipe(recipeId)
    returns (
      uint256 id,
      uint256[] memory ids,
      uint256[] memory amounts
    )
  {
    return (recipeId, _recipes[recipeId].tokenIds, _recipes[recipeId].amounts);
  }

  /// @notice Convenient function to check if recipe exists and has a set of required token IDs.
  /// @param id The Recipe ID to check
  function recipeExists(uint256 id) public view override returns (bool) {
    return _recipes[id].tokenIds.length > 0;
  }

  modifier hasRecipe(uint256 id) {
    if (!recipeExists(id)) {
      revert RecipeDoesNotExist();
    }

    _;
  }
}
