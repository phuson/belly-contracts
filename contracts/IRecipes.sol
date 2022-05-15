// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRecipes {
  function getRecipe(uint256 recipeId)
    external
    returns (
      uint256 id,
      uint256[] memory ids,
      uint256[] memory amounts
    );

  function addRecipe(
    uint256 recipeId,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  )
    external
    returns (
      uint256 id,
      uint256[] memory ids,
      uint256[] memory amts
    );

  function removeRecipe(uint256 recipeId) external;

  function recipeExists(uint256 id) external returns (bool);
}
