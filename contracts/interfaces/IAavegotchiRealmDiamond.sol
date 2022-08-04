// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAavegotchiRealmDiamond {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}
