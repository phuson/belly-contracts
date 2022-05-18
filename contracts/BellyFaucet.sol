// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBellyNft {
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;
}

/// @title NFTs distribution channel for giving out Ingredient NFTs that can be used for crafting.
/// @dev This contract must have Minter role to the main Belly NFT contract.
contract BellyFaucet is AccessControl, Pausable, ReentrancyGuard {
  IBellyNft public bellyNft;
  uint256[] public ingredientIds = [1, 2, 3, 5, 6, 7, 8, 10, 12, 13, 15, 17];

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Set the address of the main Belly NFT smart contract
  /// @dev Only Admin
  /// @param contractAddress Address for the main Belly NFT smart contract
  function setBellyNft(address contractAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    bellyNft = IBellyNft(contractAddress);
  }

  /// @notice Mint one of each ingredient NFT for playing around with the crafting functionality
  /// @param to Address to mint the set of Ingredient NFTs to
  function gimmeIngredients(address to) external nonReentrant whenNotPaused {
    uint256 idsLength = ingredientIds.length;
    uint256[] memory amounts = new uint256[](idsLength);
    uint256 i;
    for (i = 0; i < idsLength; i++) {
      amounts[i] = 1;
    }

    bellyNft.mintBatch(to, ingredientIds, amounts, "");
  }

  /*** Pause / Unpause ***/

  /// @notice Pause the contract disable minting. Admin only.
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the contract to allow minting. Admin only.
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }
}
