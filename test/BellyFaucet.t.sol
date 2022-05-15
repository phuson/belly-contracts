// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "./utils/console.sol";
import { ContractTest } from "./utils/ContractTest.sol";
import { BellyNft } from "../contracts/BellyNft.sol";
import { BellyFaucet } from "../contracts/BellyFaucet.sol";
import { NotContractAddress } from "../contracts/BellyErrors.sol";

contract BellyNftTest is ContractTest {
  event Crafted(
    address indexed sender,
    uint256 indexed recipeId,
    uint256[] ingredientIds,
    uint256[] ingredientAmounts
  );

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
  BellyFaucet public bellyFaucet;

  function setUp() public {
    vm.startPrank(ADMIN_ADDRESS);

    bellyNft = new BellyNft();
    bellyFaucet = new BellyFaucet();

    bellyFaucet.setBellyNft(address(bellyNft));

    vm.stopPrank();
  }

  function testIsPaused() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyFaucet.pause();
    assertTrue(bellyFaucet.paused());

    vm.expectRevert("Pausable: paused");
    bellyFaucet.gimmeIngredients(USER_ADDRESS);

    bellyFaucet.unpause();
    assertTrue(!bellyFaucet.paused());
  }

  function testSetBellyNft() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyFaucet.setBellyNft(address(USER_ADDRESS));
    assertEq(address(bellyFaucet.bellyNft()), address(USER_ADDRESS));
  }

  function testGimmeIngredientsAsUser() public {
    vm.prank(ADMIN_ADDRESS);
    bellyNft.grantRole(MINTER_ROLE, address(bellyFaucet));

    vm.startPrank(USER_ADDRESS);
    uint256[] memory ids = new uint256[](12);
    ids[0] = 1;
    ids[1] = 2;
    ids[2] = 3;
    ids[3] = 5;
    ids[4] = 6;
    ids[5] = 7;
    ids[6] = 8;
    ids[7] = 10;
    ids[8] = 12;
    ids[9] = 13;
    ids[10] = 15;
    ids[11] = 17;

    uint256 idsLength = ids.length;
    uint256[] memory amounts = new uint256[](idsLength);
    uint256 i;
    for (i = 0; i < idsLength; i++) {
      amounts[i] = 1;
    }
    vm.expectEmit(true, true, true, true);
    emit TransferBatch(
      address(bellyFaucet),
      address(0x0),
      address(USER_ADDRESS),
      ids,
      amounts
    );
    bellyFaucet.gimmeIngredients(USER_ADDRESS);
  }

  function testGimmeIngredientsAsUserWithoutGrantingRoleToFaucet() public {
    vm.startPrank(USER_ADDRESS);
    vm.expectRevert(
      getEncodedAccessControlError(address(bellyFaucet), MINTER_ROLE)
    );
    bellyFaucet.gimmeIngredients(USER_ADDRESS);
  }
}
