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

/// @title Main NFT contract for belly.io project.
/// @dev Make sure to add references to the recipes smart contract and crafting implementation smart contract
contract BellyNft is
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
  string public constant name = "Belly NFT";
  string public constant symbol = "BELLY";
  address public craftingContract;
  IRecipes public recipes;

  constructor() ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    setURI("https://belly.io/api/cards/");

    _setDefaultRoyalty(msg.sender, 500);
  }

  /// @notice Update and set new royalty information for NFT collection
  /// @dev Sets the default royalty information since it's the same for all token IDs
  /// @param receiver Address of the new royalty receiver
  /// @param feeNumerator Percentage of the royalty fee (10000 = 100%)
  function setRoyaltyInfo(address receiver, uint96 feeNumerator)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /// @notice Mint new NFT to a designated address
  /// @dev Only Minter Role
  /// @param account Destination address to mint to
  /// @param id NFT ID to mint
  /// @param amount Number of NFT to mint
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
    _mint(account, id, amount, data);
  }

  /// @notice Batch minting NFTs to a designated address
  /// @dev Only Minter Role
  /// @param account Destination address to mint to
  /// @param ids Arrays of IDs to mint
  /// @param amounts Arrays of amounts of NFT to mint
  function mintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
    _mintBatch(account, ids, amounts, data);
  }

  modifier whenAddressIsContract(address addr) {
    if (addr.code.length == 0) {
      revert NotContractAddress();
    }

    _;
  }

  /// @notice Delegates the crafting functionality to another smart contract
  ///         that contains the implementation details (via the Delegate Proxy Pattern)
  /// @param recipeId The recipe NFT ID to be crafted.
  function craft(uint256 recipeId)
    external
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

  /// @notice Set a new crafting smart contract by address
  /// @dev Only Admin
  /// @param addr Address of the crafting implementation contract
  function setCraftingContract(address addr)
    external
    whenAddressIsContract(addr)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    craftingContract = addr;
  }

  /// @notice Set a new recipes smart contract by address
  /// @dev Only Admin
  /// @param addr Address of the contract that contains the list of recipes
  function setRecipesContract(address addr)
    external
    whenAddressIsContract(addr)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    recipes = IRecipes(addr);
  }

  /*** Token URI setter and getter ***/

  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newuri);
  }

  /// @notice Returns the URI that points to the NFT's metadata
  /// @dev Overrides existing uri() function
  /// @param tokenId Token ID of the NFT
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

  /// @notice Returns the URI that points to the NFT's metadata
  /// @dev To support dapps that uses tokenURI() instead
  /// @param tokenId Token ID of the NFT
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  /*** Pause / Unpause ***/

  /// @notice Pause the contract disable minting
  /// @dev Only Admin
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the contract to allow minting
  /// @dev Only Admin
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
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

  /// @notice Withdraw the contract's fund
  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }("");

    require(success, "Transfer failed.");
  }

  /// @notice Reclaim ERC20 tokens from contract
  /// @param token Address of the ERC721 NFT contract to reclaim
  function reclaimFungibleToken(IERC20 token)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(address(token) != address(0), "Token address cannot be 0");
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  /// @notice Reclaim ERC1155 tokens from contract
  /// @param account Destination to send the NFTs to
  /// @param token Address of the ERC1155 NFT contract to reclaim
  /// @param ids The IDs of the NFT from the given ERC1155 NFT contract to reclaim
  /// @param data Extra data to send to {IERC1155-safeBatchTransferFrom}
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
