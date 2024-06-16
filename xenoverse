// SPDX-License-Identifier: MIT
// @author: Developed by LEADEDGE and Bunzz.
// @descpriton: NFT Minting module for general purpose.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IMintingModule.sol";

import "hardhat/console.sol";

contract MintingModule is ERC721Enumerable, Ownable, ReentrancyGuard, IMintingModule {
  using Strings for uint256;
  using Counters for Counters.Counter;

  string private baseURI;
  string public baseExtension = ".json";

  mapping(uint256 => string) private tokenURIs;
  mapping(address => uint256) private whiteLists;

  uint256 private whiteListCount = 0;
  uint256 public maxSupply;
  uint256 public preCost;
  uint256 public publicCost;
  uint256 public maxMintableQuantityPerWL;
  uint256 public mintableLimitPerTX;
  Counters.Counter private currentTokenID;

  bool public presale = true;
  bool public paused = true;

  address private royaltiesRecipientAddress;

  uint96 private defaultPercentageBasisPoints = 300; // 3%
  uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000; // 100% in bases point
  uint256 private constant MAX_ROYALTY_BASIS_POINTS = 3000; // 30%

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_,
    uint256 maxSupply_,
    uint256 preCost_,
    uint256 publicCost_,
    uint256 maxMintableQuantityPerWL_,
    uint256 mintableLimitPerTX_
  ) ERC721(name_, symbol_) {
    royaltiesRecipientAddress = payable(msg.sender);
    baseURI = baseTokenURI_;
    maxSupply = maxSupply_;
    preCost = preCost_;
    publicCost = publicCost_;
    maxMintableQuantityPerWL = maxMintableQuantityPerWL_;
    mintableLimitPerTX = mintableLimitPerTX_;
  }

  /// @notice Get status of presale
  function is_presaleActive() external view override returns (bool) {
    return presale;
  }

  /// @notice Get current cost for minting.
  function getCurrentCost() public view override returns (uint256) {
    if (presale) {
      return preCost;
    } else {
      return publicCost;
    }
  }

  /// @notice Get status of pause
  function is_paused() public view override returns (bool) {
    return paused;
  }

  /// @notice Mint NFT when public sale
  /// @dev If public sale isn't active, reverts
  /// @dev If cost is not enough, reverts
  /// @param quantity_ The count of minting tokens
  function publicMint(uint256 quantity_) public payable override nonReentrant {
    require(tx.origin == msg.sender, "NOT_EOA");
    _mintCheck(quantity_);
    require(!presale, "Public mint is paused while Presale is active.");
    require(msg.value == publicCost * quantity_, "Not enough cost or overpayment.");
    require(quantity_ <= mintableLimitPerTX, "Too many tokens to mint per transaction.");

    _safeBulkMint(quantity_);
  }

  /// @notice Mint NFT when presale
  /// @dev If presale isn't active, reverts
  /// @dev If cost is not enough, reverts
  /// @param quantity_ The count of minting tokens
  function preMint(uint256 quantity_) public payable override nonReentrant {
    _mintCheck(quantity_);

    address sender = msg.sender;
    require(presale, "Presale is not active");
    require(whiteLists[sender] >= quantity_, "Not enough tokens in white list.");
    require(msg.value == publicCost * quantity_, "Not enough cost or overpayment.");

    _safeBulkMint(quantity_);
    whiteLists[sender] -= quantity_;
  }

  /// @notice Owner can mint NFT without cost
  /// @dev If msg sender is not owner, reverts
  /// @param quantity_ The count of minting tokens
  function ownerMint(uint256 quantity_) public override onlyOwner {
    uint256 supply = totalSupply();
    require(supply + quantity_ <= maxSupply, "Total supply cannot exceed maxSupply");
    _safeBulkMint(quantity_);
  }

  /// @notice Only owner can set maxSupply
  function setMaxSupply(uint256 maxSupply_) public override onlyOwner {
    maxSupply = maxSupply_;
  }

  /// @notice Only owner can set maxMintableQuantityPerWL
  function setMaxMintableQuantityPerWL(uint256 maxMintableQuantityPerWL_) public onlyOwner {
    maxMintableQuantityPerWL = maxMintableQuantityPerWL_;
  }

  /// @notice Only owner can set mintableLimitPerTX
  function setMintableLimitPerTX(uint256 mintableLimitPerTX_) public onlyOwner {
    mintableLimitPerTX = mintableLimitPerTX_;
  }

  /// @notice Only owner can set preCost
  function setPreCost(uint256 preCost_) public onlyOwner {
    preCost = preCost_;
  }

  /// @notice Only owner can set publicCost
  function setPublicCost(uint256 publicCost_) public onlyOwner {
    publicCost = publicCost_;
  }

  /// @notice Only owner can presale state
  function setPresale(bool state_) public override onlyOwner {
    presale = state_;
  }

  /// @notice Only owner can set pause state
  function pause(bool state_) public override onlyOwner {
    paused = state_;
  }

  /// @notice Get tokenURI of tokenID
  /// @dev If tokenId is not exist, reverts
  /// @param tokenId_ The number of tokenId
  /// @return Return tokenURI
  function tokenURI(uint256 tokenId_) public view override returns (string memory) {
    require(_exists(tokenId_), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURI = tokenURIs[tokenId_];
    string memory base = _baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI, baseExtension));
    }

    return string(abi.encodePacked(base, tokenId_.toString(), baseExtension));
  }

  /// @notice Set new base token uri
  /// @dev If msg sender is not owner, reverts
  /// @param baseTokenURI_ The new base token uri
  function setBaseURI(string calldata baseTokenURI_) external override onlyOwner {
    baseURI = baseTokenURI_;
  }

  /// @notice Set token uri for sepcified token id
  /// @param tokenId_ The token id that will set token uri
  /// @param tokenURI_ The string that will set to token id
  function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external override onlyOwner {
    _setTokenURI(tokenId_, tokenURI_);
  }

  /// @notice Remove address from whitelist
  /// @dev Only owner can call this function
  /// @param addr_ The address of user that should be removed from whitelist
  function deleteWL(address addr_) external override onlyOwner {
    whiteListCount = whiteListCount - whiteLists[addr_];
    delete (whiteLists[addr_]);
  }

  /// @notice Update minting limit count for specific user
  /// @dev Only owner can call this function
  /// @param addr_ The address of user that update minting limit count
  /// @param maxMint_ The amount of new minting limit
  function updateWL(address addr_, uint256 maxMint_) public override onlyOwner {
    whiteListCount = whiteListCount - whiteLists[addr_];
    whiteLists[addr_] = maxMint_;
    whiteListCount = whiteListCount + maxMint_;
  }

  /// @notice Add several users to whitelist and update minting limit count
  /// @dev Only owner can call this function
  /// @param list_ The list of users that add to whitelist
  function pushMultiWL(address[] memory list_) public override onlyOwner {
    for (uint256 i = 0; i < list_.length; i++) {
      whiteLists[list_[i]] += maxMintableQuantityPerWL;
      whiteListCount += maxMintableQuantityPerWL;
    }
  }

  /// @notice Add several users to whitelist with specific mintable quantity and update minting limit count
  /// @dev Only owner can call this function
  /// @param list_ The list of users that add to whitelist
  function applySpecificMaxMintToMultiWL(address[] memory list_, uint256 maxMint_)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < list_.length; i++) {
      whiteLists[list_[i]] = maxMint_;
      whiteListCount += maxMint_;
    }
  }

  /// @notice Add several users to whitelist and set max mintable quantity each WL and update minting limit count
  /// @dev Only owner can call this function
  /// @param list_ The list of users that add to whitelist
  function setMaxMintEachWL(address[] memory list_, uint256[] memory maxMint_) public onlyOwner {
    for (uint256 i = 0; i < list_.length; i++) {
      whiteLists[list_[i]] = maxMint_[i];
      whiteListCount += maxMint_[i];
    }
  }

  /// @notice Mint NFT to to_ address
  /// @dev If quantity is zero, reverts
  /// @param quantity_ The count of minting tokens
  function _safeBulkMint(uint256 quantity_) internal {
    require(quantity_ > 0, "Quantity must be greater than 0");

    for (uint256 i = 0; i < quantity_; i++) {
      uint256 newTokenId = currentTokenID.current();
      currentTokenID.increment();
      _safeMint(msg.sender, newTokenId);
    }
  }

  /// @notice Set token uri for sepcified token id
  /// @param tokenId_ The token id that will set token uri
  /// @param tokenURI_ The string that will set to token id
  function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal {
    require(_exists(tokenId_), "ERC721URIStorage: URI set for nonexistent token");
    tokenURIs[tokenId_] = tokenURI_;
  }

  /// @notice Get base token uri
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Check if supply is over maxSupply
  function _mintCheck(uint256 quantity_) internal view {
    uint256 supply = totalSupply();
    require(!paused, "Minting is paused");
    require(supply + quantity_ <= maxSupply, "Total supply cannot exceed maxSupply");
  }

  /// @notice Get whiteListCount
  function getWhiteListCount() public view returns (uint256) {
    return whiteListCount;
  }

  /// @notice Get MaxMintableQuantity per WL
  function getMaxMintableQuantityPerAddress(address owner) public view returns (uint256) {
    return whiteLists[owner];
  }

  /**
   * @dev Return royality information in EIP-2981 standard.
   * @param _salePrice The sale price of the token that royality is being calculated.
   */
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (
      royaltiesRecipientAddress,
      (_salePrice * defaultPercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS
    );
  }

  /**
   * @dev Set the royalty recipient.
   * @param newRoyaltiesRecipientAddress The address of the new royalty Recipient.
   */
  function setRoyaltiesRecipientAddress(address payable newRoyaltiesRecipientAddress)
    external
    onlyOwner
  {
    require(newRoyaltiesRecipientAddress != address(0), "Address is not valid");
    royaltiesRecipientAddress = newRoyaltiesRecipientAddress;
  }

  /**
   * @dev Set the percentage basis points of the loyalty.
   * @param newDefaultPercentageBasisPoints The new percentagy basis points of the loyalty.
   */
  function setDefaultPercentageBasisPoints(uint96 newDefaultPercentageBasisPoints)
    external
    onlyOwner
  {
    require(
      newDefaultPercentageBasisPoints <= MAX_ROYALTY_BASIS_POINTS,
      "must be less than or equal to 30%"
    );
    defaultPercentageBasisPoints = newDefaultPercentageBasisPoints;
  }

  /**
   * @notice Withdraw royalties from the contract.
   * @dev Only owner can call this function
   */
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}
