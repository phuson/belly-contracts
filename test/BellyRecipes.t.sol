// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { ContractTest } from "./utils/ContractTest.sol";
import { BellyNft } from "../contracts/BellyNft.sol";
import { BellyRecipes } from "../contracts/BellyRecipes.sol";

contract BellyRecipesTest is ContractTest {
  event Combined(address indexed sender, uint256 indexed recipeId);
  event RecipeAdded(uint256 indexed recipeId);
  event RecipeRemoved(uint256 indexed recipeId);

  BellyNft public bellyNft;
  BellyRecipes public bellyRecipes;

  function setUp() public {
    vm.startPrank(ADMIN_ADDRESS);

    bellyNft = new BellyNft();
    bellyRecipes = new BellyRecipes();

    vm.stopPrank();
  }

  function testAddRecipeAsTester() public {
    vm.startPrank(USER_ADDRESS);

    uint256 recipeId = 5;

    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = 1;
    tokenIds[1] = 2;

    uint256[] memory tokenAmounts = new uint256[](2);
    tokenAmounts[0] = 1;
    tokenAmounts[1] = 2;

    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    bellyRecipes.addRecipe(recipeId, tokenIds, tokenAmounts);
  }

  function testAddRecipeAsAdmin() public {
    vm.startPrank(ADMIN_ADDRESS);

    uint256 recipeId = 5;

    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = 1;
    tokenIds[1] = 2;

    uint256[] memory tokenAmounts = new uint256[](2);
    tokenAmounts[0] = 1;
    tokenAmounts[1] = 2;

    // add recipe
    vm.expectEmit(true, true, false, true);
    emit RecipeAdded(recipeId);
    bellyRecipes.addRecipe(recipeId, tokenIds, tokenAmounts);

    // read recipe
    (
      uint256 resultId,
      uint256[] memory ids,
      uint256[] memory amounts
    ) = bellyRecipes.getRecipe(recipeId);

    assertEq(ids[0], tokenIds[0]);
    assertEq(amounts[0], tokenAmounts[0]);

    assertEq(resultId, recipeId);
  }

  function testAddRecipeFuzz(
    uint256 recipeId,
    uint256[2] calldata _tokenIds,
    uint256[2] calldata _tokenAmounts
  ) public {
    vm.assume(_tokenAmounts[0] > 0);
    vm.assume(_tokenAmounts[1] > 0);

    vm.startPrank(ADMIN_ADDRESS);

    uint256[] memory tokenIds = new uint256[](2);
    for (uint256 i = 0; i < _tokenIds.length; i += 1) {
      tokenIds[i] = _tokenIds[i];
    }

    uint256[] memory tokenAmounts = new uint256[](2);
    for (uint256 i = 0; i < _tokenAmounts.length; i += 1) {
      tokenAmounts[i] = _tokenAmounts[i];
    }

    // add recipe
    vm.expectEmit(true, true, false, true);
    emit RecipeAdded(recipeId);
    bellyRecipes.addRecipe(recipeId, tokenIds, tokenAmounts);

    // read recipe
    (
      uint256 resultId,
      uint256[] memory ids,
      uint256[] memory amounts
    ) = bellyRecipes.getRecipe(recipeId);

    for (uint256 i = 0; i < _tokenIds.length; i += 1) {
      assertEq(ids[i], _tokenIds[i]);
    }

    for (uint256 i = 0; i < _tokenAmounts.length; i += 1) {
      assertEq(amounts[i], _tokenAmounts[i]);
    }

    assertEq(recipeId, resultId);
  }
}
