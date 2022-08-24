// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/INFT.sol";

contract NFT is INFT, ERC721URIStorage, AccessControl, Pausable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenId;

  string private _baseTokenURI;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant CONTRACT_MASTER_ROLE =
    keccak256("CONTRACT_MASTER_ROLE");

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI
  ) ERC721(name, symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(CONTRACT_MASTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _baseTokenURI = baseURI;
  }

  function setupMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE, minter);
  }

  function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(MINTER_ROLE, minter);
  }

  function setupContractMaster(address _addr)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    grantRole(CONTRACT_MASTER_ROLE, _addr);
  }

  function removeContractMaster(address _addr)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    revokeRole(CONTRACT_MASTER_ROLE, _addr);
  }

  function setupBurner(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(BURNER_ROLE, _addr);
  }

  function removeBurner(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(BURNER_ROLE, _addr);
  }

  /**
   * Override `ERC721URIStorage`.
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function mint(string memory uri)
    external
    whenNotPaused
    onlyRole(MINTER_ROLE)
  {
    _mintAndTransfer(uri, msg.sender);
  }

  function mintAndTransfer(string memory uri, address owner)
    external
    whenNotPaused
    onlyRole(MINTER_ROLE)
    returns (uint256)
  {
    return _mintAndTransfer(uri, owner);
  }

  function _mintAndTransfer(string memory uri, address owner)
    internal
    whenNotPaused
    returns (uint256)
  {
    require(owner != address(0), "NFT: owner must not be 0");
    require(bytes(uri).length != 0, "NFT: token's URI must not be empty");

    uint256 currentTokenId = _tokenId.current();
    _tokenId.increment();

    _safeMint(owner, currentTokenId);
    _setTokenURI(currentTokenId, uri);
    return currentTokenId;
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    external
    whenNotPaused
    onlyRole(CONTRACT_MASTER_ROLE)
  {
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 tokenId) external whenNotPaused onlyRole(BURNER_ROLE) {
    _burn(tokenId);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external whenNotPaused onlyRole(CONTRACT_MASTER_ROLE) {
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function transfer(
    address from,
    address to,
    uint256 tokenId
  ) external whenNotPaused onlyRole(CONTRACT_MASTER_ROLE) {
    _transfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControl)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
