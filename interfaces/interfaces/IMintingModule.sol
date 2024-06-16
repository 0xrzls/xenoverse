// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintingModule {
  function is_presaleActive() external view returns (bool);

  function getCurrentCost() external view returns (uint256);

  function is_paused() external view returns (bool);

  function publicMint(uint256 quantity_) external payable;

  function preMint(uint256 quantity_) external payable;

  function ownerMint(uint256 quantity_) external;

  function setMaxSupply(uint256 maxSupply_) external;

  function setPresale(bool state_) external;

  function pause(bool state_) external;

  function setBaseURI(string calldata baseTokenURI_) external;

  function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external;

  function deleteWL(address addr_) external;

  function updateWL(address addr_, uint256 maxMint_) external;

  function pushMultiWL(address[] memory list_) external;
}
