// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRecipes.sol";
import "./BellyErrors.sol";

contract BellyPacks is
  ERC1155,
  ERC1155Burnable,
  ERC1155Supply,
  ERC1155Holder,
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
  string public constant name = "Belly Packs";
  string public constant symbol = "BELLYPACK";
  address public craftingContract;
  IRecipes public recipes;

  constructor() ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    setURI("https://belly.io/api/packs/");

    _setDefaultRoyalty(msg.sender, 500);
  }

  function setRoyaltyInfo(address receiver, uint96 feeNumerator)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
    _mintBatch(to, ids, amounts, data);
  }

  modifier whenAddressIsContract(address addr) {
    if (addr.code.length == 0) {
      revert NotContractAddress();
    }

    _;
  }

  function craft(uint256 recipeId)
    public
    payable
    virtual
    nonReentrant
    whenNotPaused
    returns (bytes memory)
  {
    (bool success, bytes memory returndata) = craftingContract.delegatecall(
      abi.encodeWithSignature("craft(uint256)", recipeId)
    );

    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("Failed to delegatecall to craft");
      }
    }
  }

  /*** Token URI setter and getter ***/

  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newuri);
  }

  function uri(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(exists(tokenId), "Nonexistent token");

    return string.concat(super.uri(tokenId), Strings.toString(tokenId));
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return uri(tokenId);
  }

  /*** Pause / Unpause ***/

  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
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
    override(ERC1155, AccessControl, ERC1155Receiver, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /*** Withdraw and receive fallback ***/

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }("");

    require(success, "Transfer failed.");
  }

  // reclaim ERC20 tokens
  function reclaimFungibleToken(IERC20 token)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(address(token) != address(0), "Token address cannot be 0");
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  // reclaim ERC1155 tokens
  function reclaimTokenBatch(
    address account,
    IERC1155 token,
    uint256[] memory ids,
    bytes memory data
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(token) != address(0), "Token address cannot be 0");

    // compile the array of addresses for the batch call
    uint256 idsLength = ids.length;
    address[] memory addresses = new address[](idsLength);
    for (uint256 i = 0; i < idsLength; i++) {
      addresses[i] = address(this);
    }
    uint256[] memory balances = token.balanceOfBatch(addresses, ids);

    token.safeBatchTransferFrom(address(this), account, ids, balances, data);
  }

  receive() external payable {}
}
