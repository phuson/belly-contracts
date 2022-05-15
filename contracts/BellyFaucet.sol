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

contract BellyFaucet is AccessControl, Pausable, ReentrancyGuard {
  IBellyNft public bellyNft;
  uint256[] public ingredientIds = [1, 2, 3, 5, 6, 7, 8, 10, 12, 13, 15, 17];

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setBellyNft(address contractAddress)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    bellyNft = IBellyNft(contractAddress);
  }

  function gimmeIngredients(address to) public nonReentrant whenNotPaused {
    uint256 idsLength = ingredientIds.length;
    uint256[] memory amounts = new uint256[](idsLength);
    uint256 i;
    for (i = 0; i < idsLength; i++) {
      amounts[i] = 1;
    }

    bellyNft.mintBatch(to, ingredientIds, amounts, "");
  }

  /*** Pause / Unpause ***/

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }
}
