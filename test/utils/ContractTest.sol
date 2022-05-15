// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ContractTest is Test {
  address public constant ADMIN_ADDRESS = address(11);
  address public constant USER_ADDRESS = address(22);
  address public constant BURN_ADDRESS = address(0xdead);

  // from OZ AccessControl
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function getEncodedAccessControlError(address account, bytes32 role)
    public
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        "AccessControl: account ",
        Strings.toHexString(uint160(account), 20),
        " is missing role ",
        Strings.toHexString(uint256(role), 32)
      );
  }
}
