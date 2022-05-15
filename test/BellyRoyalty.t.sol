// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { console } from "./utils/console.sol";
import { ContractTest } from "./utils/ContractTest.sol";
import { BellyNft } from "../contracts/BellyNft.sol";

contract BellyNftTest is ContractTest {
  BellyNft public bellyNft;

  function setUp() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft = new BellyNft();
    vm.stopPrank();
  }

  function testRoyalty(uint256 tokenId) public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.mint(USER_ADDRESS, tokenId, 1, "");
    vm.stopPrank();

    assertEq(bellyNft.balanceOf(USER_ADDRESS, tokenId), 1);

    (address royaltyAddress, uint256 royaltyAmount) = bellyNft.royaltyInfo(
      tokenId,
      100 ether
    );
    assertEq(royaltyAddress, ADMIN_ADDRESS);
    assertEq(royaltyAmount, 5 ether);

    (address royaltyAddress2, uint256 royaltyAmount2) = bellyNft.royaltyInfo(
      tokenId,
      10 ether
    );
    assertEq(royaltyAddress2, ADMIN_ADDRESS);
    assertEq(royaltyAmount2, 0.5 ether);
  }

  function testSetRoyalty() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.mint(USER_ADDRESS, 2, 5, "");
    vm.stopPrank();

    assertEq(bellyNft.balanceOf(USER_ADDRESS, 2), 5);
    (address royaltyAddress, uint256 royaltyAmount) = bellyNft.royaltyInfo(
      2,
      100 ether
    );
    assertEq(royaltyAddress, ADMIN_ADDRESS);
    assertEq(royaltyAmount, 5 ether);

    vm.prank(ADMIN_ADDRESS);
    bellyNft.setRoyaltyInfo(USER_ADDRESS, 1000);
    (address royaltyAddress2, uint256 royaltyAmount2) = bellyNft.royaltyInfo(
      2,
      100 ether
    );
    assertEq(royaltyAddress2, USER_ADDRESS);
    assertEq(royaltyAmount2, 10 ether);
  }

  function testSetRoyaltyAsUser() public {
    vm.startPrank(ADMIN_ADDRESS);
    bellyNft.mint(USER_ADDRESS, 1, 1, "");
    bellyNft.mint(USER_ADDRESS, 2, 5, "");
    vm.stopPrank();

    vm.expectRevert(
      getEncodedAccessControlError(USER_ADDRESS, DEFAULT_ADMIN_ROLE)
    );
    vm.prank(USER_ADDRESS);
    bellyNft.setRoyaltyInfo(USER_ADDRESS, 1000);
  }
}
