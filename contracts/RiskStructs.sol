// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";

// Enum for different types of cards in the game.
enum Cards {
    GARRISON, // +10 troops
    ARTILLERY, // Destroy 1/4 of troops on any square
    BAMBA, // Destory 3/4 of troops on any square
    INTEL // See 3 squares
}

// Struct to represent the state of the game.
struct GameState {
    uint256 gameID; // Unique identifier for the game.
    address[] players; // List of player addresses in the game.
    mapping(address => Player) playerInfo; // Mapping from player addresses to their respective Player structs.
    mapping(uint256 => Territory) territoryInfo; // Mapping from territory IDs to their respective Territory structs.
    uint256 currentTurn; // Index of the player whose turn it is.
    bool active; // Boolean to indicate if the game is currently active.
    euint8[42] territoryOwners; // Array to store the owner of each territory
    mapping(uint256 => mapping(address => ebool)) intel;
}

// Struct to represent a player in the game.
struct Player {
    address playerAddress; // Address of the player.
    euint8 index;
    euint32 totalTroops; // Total number of troops the player has.
    euint32 totalGold; // Total amount of gold the player has.
    mapping(euint32 => euint32) cardCount; // Mapping from card types to the count of each card the player owns.
}

// Struct to represent a territory in the game.
struct Territory {
    uint256 territoryID; // Unique identifier for the territory.
    euint32 troopsHere; // Number of troops stationed in the territory.
    uint256[] neighbors; // Array of territory IDs that are neighbors to this territory.
}
