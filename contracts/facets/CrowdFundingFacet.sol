// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { AppStorage, FarmingOperation, aavegotchiRealmDiamond, aavegotchiInstallationDiamond } from "../libraries/LibAppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IAavegotchiRealmDiamond } from "../interfaces/IAavegotchiRealmDiamond.sol";
import { IAavegotchiInstallationDiamond, InstallationType } from "../interfaces/IAavegotchiInstallationDiamond.sol";

/// @title Trustless Crowd Funding for a Gotchiverse Farming Operation
/// @author gotchistats.lens
/// @notice You can use this contract for creating and manage a Gotchiverse crowd funding farming operation

contract CrowdFundingFacet {
    AppStorage internal s;

    /// @notice deposits a Gotchiverse land parcel into a smart contract and creates a farming operation
    /// @param _landTokenId the land ERC721 token id that will be used in the farming operation
    /// @param _installationIds array of Gotchiverse REALM installation IDs that need to be built on the land parcel (must be the same length as _installationQuantities)
    /// @param _installationQuantities array of quantities of the Gotchiverse REALM installations that need to be built on the land parcel (must be the same length as _installationIds)
    /// @param _instaBuild will GLTR be used for insta-building and insta-upgrading all installations
    /*
        createFarmingOperation

        Called by a land owner that wants to create a crowd funded farming operation
        The land owner will deposit one land ERC721 token into the smart contract
        The land owner specifies the build that will be applied to this land
        The land owner specifies the shares that will be granted for this land, and the shares that will be granted to participants supply the building materials ERC20s
     */
    function createFarmingOperation(
        uint256 _landTokenId,
        uint256[] calldata _installationIds,
        uint256[] calldata _installationQuantities,
        bool _instaBuild
    ) external {
        require(_installationIds.length > 0, "Missing installation IDs");
        require(_installationQuantities.length > 0, "Missing installation quantities");
        require(_installationIds.length == _installationQuantities.length, "Installation IDs and quantities must be the same size");
        require(msg.sender == IAavegotchiRealmDiamond(aavegotchiRealmDiamond).ownerOf(_landTokenId), "Sender must own the land parcel");

        // check installation ids are all valid
        // check installation quantities are valid for the parcel size
        // check land has been surveyed at least once

        uint256 newOperationId = s.farmingOperations.length;

        // use aavegotchi interfaces to move the land into the smart contract
        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(msg.sender, address(this), _landTokenId);

        uint256[] memory budget = calculateBudget(_installationIds, _installationQuantities, _instaBuild);
        
        FarmingOperation memory farmingOperation = FarmingOperation(
            newOperationId,
            _landTokenId,
            _installationIds, 
            _installationQuantities,
            _instaBuild,
            msg.sender,
            budget,
            true
        );

        s.farmingOperations.push(farmingOperation);
    }

    function withdrawLandFromOperation(uint256 _operationId, uint256 _tokenId) external {
        require(address(this) == IAavegotchiRealmDiamond(aavegotchiRealmDiamond).ownerOf(_tokenId), "Smart contract must own the land parcel");
        require(msg.sender == s.farmingOperations[_operationId].landSupplier, "Sender must be the operation land supplier");
        require(s.farmingOperations[_operationId].landDeposited == true, "Land must be deposited for this farming operation");
        require(s.farmingOperations[_operationId].landTokenId == _tokenId, "Land Token ID must match what was deposited for this farming operation");

        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(address(this), msg.sender, _tokenId);
        s.farmingOperations[_operationId].landDeposited = false;
    }

    function calculateBudget(uint256[] calldata _installationIds, uint256[] calldata _installationQuantities, bool _instaBuild) internal returns(uint256[] memory) {
        // todo fix a bug in this implementation. if you add a level 3 installation, you need to go back and add the costs for level 1 and level 2 of that installation aswell, not just level 3
        uint256[] memory budget = new uint[](5);
        InstallationType[] memory installationTypes = IAavegotchiInstallationDiamond(aavegotchiInstallationDiamond).getInstallationTypes(_installationIds);

        for (uint i = 0; i < _installationIds.length; i++) {
            budget[0] += installationTypes[i].alchemicaCost[0] * _installationQuantities[i];
            budget[1] += installationTypes[i].alchemicaCost[1] * _installationQuantities[i];
            budget[2] += installationTypes[i].alchemicaCost[2] * _installationQuantities[i];
            budget[3] += installationTypes[i].alchemicaCost[3] * _installationQuantities[i];
            if (_instaBuild) {
                budget[4] += installationTypes[i].craftTime * _installationQuantities[i];
            }
        }

        return budget;
    }

    // function depositERC20IntoOperation(uint256 _operationId, address _tokenAddress, uint256 _amount) {

    // }

    // function withdrawERC20FromOperation(uint256 _operationId, address _tokenAddress, uint256 _amount) {

    // }

    // function getOperationERC20Balances(uint256 _operationId) {

    // }

    // function getOperationBalanceByERC20(uint256 _operationId, address _tokenAddress) {

    // }

    // function getOperationERC721Balance(uint256 _operationId) {

    // }
}
