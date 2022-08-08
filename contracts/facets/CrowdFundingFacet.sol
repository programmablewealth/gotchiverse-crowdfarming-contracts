// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { ERC721Holder } from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibMeta } from "../libraries/LibMeta.sol";

import {
    AppStorage, FarmingOperation,
    aavegotchiRealmDiamond, aavegotchiInstallationDiamond
} from "../libraries/LibAppStorage.sol";

import { IAavegotchiRealmDiamond } from "../interfaces/IAavegotchiRealmDiamond.sol";
import { IAavegotchiInstallationDiamond, InstallationType } from "../interfaces/IAavegotchiInstallationDiamond.sol";

/// @title Trustless Crowd Funding for a Gotchiverse Farming Operation
/// @author gotchistats.lens
/// @notice You can use this contract for creating and manage a Gotchiverse crowd funding farming operation

contract CrowdFundingFacet is ERC721Holder {
    AppStorage internal s;

    /// @notice deposits a Gotchiverse land parcel into a smart contract and creates a farming operation
    /// @param _landTokenId the land ERC721 token id that will be used in the farming operation
    /// @param _installationIds array of Gotchiverse REALM installation IDs that need to be built on the land parcel (must be the same length as _installationQuantities)
    /// @param _installationQuantities array of quantities of the Gotchiverse REALM installations that need to be built on the land parcel (must be the same length as _installationIds)
    /// @param _instaBuild will GLTR be used for insta-building and insta-upgrading all installations
    /// @param _totalShares total number of shares that will be available in this farming operation
    /// @param _sharesForLand number of shares out of the total numbers that will be assigned to the land provider
    /// @param _shareRatiosForMaterials FUD dominated ratios for shares offered to investors in the operation provided FUD, FOMO, ALPHA, KEK, and GLTR
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
        bool _instaBuild,
        uint256 _totalShares,
        uint256 _sharesForLand,
        uint256[] calldata _shareRatiosForMaterials
    ) external {
        require(_installationIds.length > 0, "CrowdFundingFacet: Error - Missing installation IDs");
        require(_installationIds.length == _installationQuantities.length, "CrowdFundingFacet: Error - Installation IDs and quantities must be the same size");
        require(_totalShares > _sharesForLand, "CrowdFundingFacet: Error - Total shares must be greater than the number of shares provided to the land owner");
        require(_shareRatiosForMaterials.length == 5, "CrowdFundingFacet: Error - Must provide a share ratio for FUD, FOMO, ALPHA, KEK, and GLTR");

        // check installation ids are all valid
        // check installation quantities are valid for the parcel size
        // check land has been surveyed at least once

        // todo: set a max % for emptyiers and emptyier management upfront
        // todo: set a builders fee upfront

        uint256 newOperationId = s.farmingOperationCount;

        // use aavegotchi interfaces to move the land into the smart contract
        address sender = LibMeta.msgSender();
        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(sender, address(this), _landTokenId);

        s.farmingOperations[newOperationId] = FarmingOperation({
            operationId: newOperationId,
            landTokenId: _landTokenId,
            installationIds: _installationIds, 
            installationQuantities: _installationQuantities,
            instaBuild: _instaBuild,
            landSupplier: sender,
            budget: this.calculateBudget(_installationIds, _installationQuantities, _instaBuild),
            totalShares: _totalShares,
            sharesForLand: _sharesForLand,
            shareRatiosForMaterials: _shareRatiosForMaterials,
            landDeposited: true
        });

        s.farmingOperationCount++;
    }
    
    function withdrawLandFromOperation(uint256 _operationId, uint256 _tokenId) external {
        address sender = LibMeta.msgSender();

        require(sender == s.farmingOperations[_operationId].landSupplier, "CrowdFundingFacet: Error - Sender must be the operation land supplier");
        require(s.farmingOperations[_operationId].landDeposited, "CrowdFundingFacet: Error - Land must be deposited for this farming operation");
        require(s.farmingOperations[_operationId].landTokenId == _tokenId, "CrowdFundingFacet: Error - Land Token ID must match what was deposited for this farming operation");

        IAavegotchiRealmDiamond(aavegotchiRealmDiamond).safeTransferFrom(address(this), sender, _tokenId);
        s.farmingOperations[_operationId].landDeposited = false;
    }

    function calculateBudget(
        uint256[] calldata _installationIds, uint256[] calldata _installationQuantities, bool _instaBuild
    ) external view returns(uint256[] memory) {
        // todo fix a bug in this implementation. if you add a level 3 installation, you need to go back and add the costs for level 1 and level 2 of that installation aswell, not just level 3
        uint256[] memory budget = new uint256[](5);
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
