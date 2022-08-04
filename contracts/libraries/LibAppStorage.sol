// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { LibDiamond } from "./LibDiamond.sol";

// constants
address constant aavegotchiDiamond = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
address constant aavegotchiRealmDiamond = 0x1D0360BaC7299C86Ec8E99d0c1C9A95FEfaF2a11;
address constant aavegotchiInstallationDiamond = 0x19f870bD94A34b3adAa9CaA439d333DA18d6812A;
// address constant landERC721Contract = "";
// address constant ghstERC20Contract = "";
// address constant fudERC20Contract = "";
// address constant fomoERC20Contract = "";
// address constant alphaERC20Contract = "";
// address constant kekERC20Contract = "";
// address constant gltrERC20Contract = "";

// structs
struct FarmingOperation {
    uint256 operationId;
    uint256 landTokenId;
    uint256[] installationIds;
    uint256[] installationQuantities;
    bool instaBuild;
    address landSupplier;
    uint256[] budget;
    bool landDeposited;
}

struct AppStorage {
    FarmingOperation[] farmingOperations;
    
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// modifiers
contract Modifiers {
    AppStorage internal s;
}
