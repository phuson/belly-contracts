// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { console } from "./utils/console.sol";
import { ContractTest } from "./utils/ContractTest.sol";
import { BellyNft } from "../contracts/BellyNft.sol";
import { BellyNftCrafting } from "../contracts/BellyNftCrafting.sol";
import { BellyNftCrafting2 } from "../contracts/BellyNftCrafting2.sol";
import { BellyRecipes } from "../contracts/BellyRecipes.sol";
import { NotContractAddress } from "../contracts/BellyErrors.sol";

contract BellyNftTest is ContractTest {
  event Crafted(
    address indexed sender,
    uint256 indexed recipeId,
    uint256[] ingredientIds,
    uint256[] ingredientAmounts
  );
  event RecipeAdded(uint256 indexed recipeId, uint256 indexed resultTokenId);
  event RecipeRemoved(uint256 indexed recipeId);

  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  BellyNft public bellyNft;
  BellyNftCrafting public bellyNftCrafting;
  BellyRecipes public bellyRecipes;

  function setUp() public {
    vm.startPrank(ADMIN_ADDRESS);

    bellyNft = new BellyNft();
    bellyRecipes = new BellyRecipes();
    bellyNftCrafting = new BellyNftCrafting();

    vm.stopPrank();
  }

  function testIsPaused() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.pause();
    assertTrue(bellyNft.paused());

    vm.expectRevert("Pausable: paused");
    bellyNft.mint(USER_ADDRESS, 1, 1, "");

    bellyNft.unpause();
    assertTrue(!bellyNft.paused());
  }

  // setURI

  function testSetURI(string memory newUri) public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.setURI(newUri);

    bellyNft.mint(USER_ADDRESS, 1, 1, "");

    assertEq(bellyNft.uri(1), string.concat(newUri, "1"));
  }

  function testSetURIAsUser() public {
    vm.prank(USER_ADDRESS);
    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    bellyNft.setURI("new");
  }

  // setCraftingContract

  function testSetCraftingContractWithNonContractAddressFuzz(
    address contractAddress
  ) public {
    vm.assume(contractAddress != address(bellyNftCrafting));
    vm.assume(contractAddress != address(bellyRecipes));
    vm.assume(contractAddress != address(bellyNft));
    vm.assume(contractAddress != address(this));

    vm.startPrank(ADMIN_ADDRESS);
    vm.expectRevert(abi.encodeWithSignature("NotContractAddress()"));
    bellyNft.setCraftingContract(contractAddress);
    vm.stopPrank();
  }

  function testSetCraftingContractWithNonAdmin() public {
    vm.startPrank(USER_ADDRESS);
    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    bellyNft.setCraftingContract(address(bellyNftCrafting));
    vm.stopPrank();
  }

  // setRecipesContract

  function testSetRecipesContractWithNonContractAddressFuzz(
    address contractAddress
  ) public {
    vm.assume(contractAddress != address(address(this)));
    vm.assume(contractAddress != address(bellyNftCrafting));
    vm.assume(contractAddress != address(bellyRecipes));
    vm.assume(contractAddress != address(bellyNft));

    vm.startPrank(ADMIN_ADDRESS);
    vm.expectRevert(abi.encodeWithSignature("NotContractAddress()"));
    bellyNft.setRecipesContract(contractAddress);
    vm.stopPrank();
  }

  function testSetRecipesContractWithNonAdmin() public {
    vm.startPrank(USER_ADDRESS);
    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    bellyNft.setRecipesContract(address(bellyRecipes));
    vm.stopPrank();
  }

  function testCraftBase() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.setRecipesContract(address(bellyRecipes));
    bellyNft.setCraftingContract(address(bellyNftCrafting));

    assertEq(address(bellyNft.recipes()), address(bellyRecipes));
    assertEq(bellyNft.craftingContract(), address(bellyNftCrafting));

    uint256 recipeId = 5;

    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = 1;
    tokenIds[1] = 2;

    uint256[] memory tokenAmounts = new uint256[](2);
    tokenAmounts[0] = 1;
    tokenAmounts[1] = 1;

    // mint ingredients
    bellyNft.mint(USER_ADDRESS, 1, 2, "");
    bellyNft.mint(USER_ADDRESS, 2, 2, "");

    assertEq(bellyNft.balanceOf(USER_ADDRESS, 1), 2);
    assertEq(bellyNft.balanceOf(USER_ADDRESS, 2), 2);

    // add recipe
    bellyRecipes.addRecipe(recipeId, tokenIds, tokenAmounts);

    vm.stopPrank();

    assertEq(bellyNft.balanceOf(USER_ADDRESS, 5), 0);

    vm.prank(USER_ADDRESS);
    vm.expectEmit(true, true, true, true);
    // check to make sure tokens are transferred to zero address
    emit TransferBatch(
      address(address(USER_ADDRESS)),
      address(address(USER_ADDRESS)),
      address(0x0),
      tokenIds,
      tokenAmounts
    );
    vm.expectEmit(true, true, true, true);
    // check to make sure tokens are transferred to zero address
    emit Crafted(
      address(address(USER_ADDRESS)),
      recipeId,
      tokenIds,
      tokenAmounts
    );
    bellyNft.craft(recipeId);

    assertEq(bellyNft.balanceOf(USER_ADDRESS, 5), 1);
  }

  function testCraftUpgrade() public {
    testCraftBase();
    uint256 recipeId = 1;

    vm.startPrank(ADMIN_ADDRESS);
    BellyNftCrafting2 craft2 = new BellyNftCrafting2();

    assertTrue(bellyNft.craftingContract() != address(craft2));
    bellyNft.setCraftingContract(address(craft2));
    assertTrue(bellyNft.craftingContract() == address(craft2));

    vm.expectRevert("Craft Contract Updated");
    bellyNft.craft(recipeId);
  }

  // reclaiming tokens

  function testReclaimTokenBatchAsAdmin() public {
    uint256[] memory reclaimIds = new uint256[](1);
    reclaimIds[0] = 1;
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.reclaimTokenBatch(USER_ADDRESS, bellyNft, reclaimIds, "");
  }

  function testReclaimTokenBatchAsUser() public {
    uint256[] memory reclaimIds = new uint256[](1);
    reclaimIds[0] = 1;
    vm.startPrank(USER_ADDRESS);
    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    bellyNft.reclaimTokenBatch(USER_ADDRESS, bellyNft, reclaimIds, "");
  }

  function testReclaimTokenBatchMultipleTokens(uint256 number) public {
    vm.assume(number < 100);

    uint256[] memory ids = new uint256[](number);
    uint256[] memory amounts = new uint256[](number);
    for (uint256 i = 0; i < number; i++) {
      ids[i] = i;
      amounts[i] = i + 10;
    }

    vm.startPrank(ADMIN_ADDRESS);

    // mint tokens to contract to test reclaiming
    bellyNft.mintBatch(address(bellyNft), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      assertEq(bellyNft.balanceOf(address(bellyNft), ids[i]), amounts[i]);
    }

    vm.expectEmit(true, true, true, true);
    emit TransferBatch(
      address(bellyNft),
      address(bellyNft),
      address(USER_ADDRESS),
      ids,
      amounts
    );
    bellyNft.reclaimTokenBatch(USER_ADDRESS, bellyNft, ids, "");
    for (uint256 i = 0; i < ids.length; i++) {
      assertEq(bellyNft.balanceOf(USER_ADDRESS, ids[i]), amounts[i]);
    }

    // after reclaim, contract should not longer have any tokens
    for (uint256 i = 0; i < ids.length; i++) {
      assertEq(bellyNft.balanceOf(address(bellyNft), ids[i]), 0);
    }
  }
}
