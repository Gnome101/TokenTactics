// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;
import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";
import "./RiskStructs.sol";
event Garrison(uint256 gameID);
event Artillery(uint256 gameID, uint256 territoryID);
event Bamba(uint256 gameID, uint256 territoryID);
event Intel(uint256 gameID, uint256 territoryID);

event GameStarted(uint256 gameID);
event TurnEnded(uint256 gameID, address player);
event GameEnded(uint256 gameID, address winner);

contract RiskGame is EIP712WithModifier {
    using TFHE for uint256;
    uint256 public gameCounter;
    mapping(uint256 => GameState) public games;
    mapping(address => uint256) public playerWins;
    uint256 constant troopStart = 5;
    uint256 constant goldStart = 10;
    address public contractOwner;

    constructor() EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;
    }

    function createGame() public {
        gameCounter++;
        GameState storage newGame = games[gameCounter];
        newGame.gameID = gameCounter;
        joinGame(gameCounter);
        gameCounter++;
        newGame.active = true;
    }

    function joinGame(uint256 gameID) public {
        require(games[gameID].active, "Game is not active");
        GameState storage chosenGame = games[gameID];

        chosenGame.players.push(msg.sender);
        chosenGame.playerInfo[msg.sender].playerAddress = msg.sender;
        chosenGame.playerInfo[msg.sender].totalTroops = troopStart.asEuint32();
        chosenGame.playerInfo[msg.sender].totalGold = goldStart.asEuint32();
        chosenGame.playerInfo[msg.sender].index = (chosenGame.players.length -
            1).asEuint8();
    }

    function randomlySelect(
        uint256 gameID
    ) internal returns (uint256 startPlayer) {
        GameState storage activeGame = games[gameID];
        address[] memory playerAddys = activeGame.players;
        uint256 playerCount = playerAddys.length;

        // Preset the unassignedTerritories array
        uint256[42] memory unassignedTerritories = [
            uint256(0),
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
            31,
            32,
            33,
            34,
            35,
            36,
            37,
            38,
            39,
            40,
            41
        ];
        uint256 counter = 42;

        // Randomly select a player to start
        euint32 randomNumber = TFHE.randEuint32();
        startPlayer = uint256(TFHE.decrypt(randomNumber)) % playerCount;

        // Assign 5 territories to each player in a round-robin manner
        for (uint256 i = 0; i < 5 * playerCount; i++) {
            uint256 currentPlayerIndex = (startPlayer + i) % playerCount;
            address currentPlayer = playerAddys[currentPlayerIndex];

            uint256 randIndex = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        currentPlayer,
                        i
                    )
                )
            ) % counter;
            uint256 selectedTerritoryID = unassignedTerritories[randIndex];

            // Assign the territory to the player and place one troop there
            activeGame.territoryInfo[selectedTerritoryID].troopsHere = TFHE
                .asEuint32(1);
            activeGame.territoryOwners[selectedTerritoryID] = currentPlayerIndex
                .asEuint8();

            // Remove the selected territory from the unassignedTerritories array
            unassignedTerritories[randIndex] = unassignedTerritories[
                counter - 1
            ];
            counter--;
        }
    }

    function startGame(uint256 gameID) public {
        require(
            games[gameID].players[0] == msg.sender,
            "Only game owner can start the game"
        );
        GameState storage game = games[gameID];

        game.currentTurn = randomlySelect(gameID);
        startTurn(gameID);
        emit GameStarted(gameID);
    }

    function endTurn(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(game.players[game.currentTurn] == msg.sender, "Not your turn");
        emit TurnEnded(gameID, msg.sender);
        game.currentTurn = (game.currentTurn + 1) % game.players.length;
        startTurn(gameID);
        
    }

    function moveTroops(
        uint256 gameID,
        uint8 from,
        uint8 to,
        euint32 amount
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        Territory storage source = game.territoryInfo[from];
        Territory storage target = game.territoryInfo[to];
        TFHE.optReq(TFHE.gt(1, source.troopsHere));
        TFHE.optReq(TFHE.le(amount, TFHE.sub(source.troopsHere, 1))); //"Not enough troops"
        require(isNeighbor(gameID, from, to), "Territories not neighbors");
        TFHE.optReq(playerOwnsTerritory(player, from, gameID)); //Player must own territory

        if (TFHE.decrypt(playerOwnsTerritory(player, to, gameID))) {
            removeTroopsHere(source, amount);
            addTroopsHere(target, amount);
        } else {
            resolveBattle(game, from, to, amount);
        }
    }

    function addTroopsHere(Territory storage target, euint32 amount) internal {
        target.troopsHere = TFHE.add(target.troopsHere, amount);
    }

    function removeTroopsHere(
        Territory storage target,
        euint32 amount
    ) internal {
        target.troopsHere = TFHE.sub(
            target.troopsHere,
            TFHE.min(amount, target.troopsHere)
        );
    }

    function purchaseTroops(uint256 gameID, euint32 amount) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        euint32 cost = TFHE.mul(amount, TFHE.asEuint32(1)); // Assume 1 gold per troop
        TFHE.optReq(TFHE.le(cost, player.totalGold)); //Player needs min gold
        player.totalGold = TFHE.sub(player.totalGold, cost);
        player.totalTroops = TFHE.add(player.totalTroops, amount);
    }

    function useCard(
        uint256 gameID,
        uint32 cardToUse,
        uint256 territoryID
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        euint32 cardType = TFHE.asEuint32(cardToUse);

        TFHE.optReq(TFHE.ge(7, player.cardCount[cardType])); //Player needs 7 cards
        Territory storage territory = game.territoryInfo[territoryID];

        if (cardToUse == 0) {
            player.totalTroops = TFHE.add(
                player.totalTroops,
                TFHE.asEuint32(10)
            );
            emit Garrison(gameID);
        } else if (cardToUse == 1) {
            // Implement ARTILLERY logic
            //Should detroy 25% on this cell
            territory.troopsHere = TFHE.mul(territory.troopsHere, 750);
            territory.troopsHere = TFHE.div(territory.troopsHere, 1000);
            emit Artillery(gameID,territoryID);
        } else if (cardToUse == 2) {
            // Implement BAMBA logic
            territory.troopsHere = TFHE.mul(territory.troopsHere, 200);
            territory.troopsHere = TFHE.div(territory.troopsHere, 1000);
            emit Bamba(gameID,territoryID);

        } else if (cardToUse == 3) {
            // Implement INTEL logic
            game.intel[territoryID][player.playerAddress] = TFHE.asEbool(true);
            emit Intel(gameID,territoryID);
        }

        player.cardCount[cardType] = TFHE.sub(player.cardCount[cardType], 7);
    }

    function declareVictory(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(game.players.length == 1, "Game not finished");
        playerWins[game.players[0]]++;
    }

    function startTurn(uint256 gameID) internal {
        GameState storage game = games[gameID];
        Player storage currentPlayer = game.playerInfo[
            game.players[game.currentTurn]
        ];

        // Give a random card to the current player
        euint32 randomCardIndex = TFHE.rem(TFHE.randEuint32(), 4); // Assuming 4 types of cards

        currentPlayer.cardCount[randomCardIndex] = TFHE.add(
            currentPlayer.cardCount[randomCardIndex],
            TFHE.asEuint32(1)
        );

        // Calculate the amount of gold to give based on the number of territories owned
        euint32 goldToGive = TFHE.asEuint32(0);
        for (uint256 i = 0; i < 42; i++) {
            ebool owns = TFHE.eq(game.territoryOwners[i], currentPlayer.index);
            goldToGive = TFHE.add(
                goldToGive,
                TFHE.cmux(owns, TFHE.asEuint32(1), TFHE.asEuint32(0))
            );
        }
        currentPlayer.totalGold = TFHE.add(currentPlayer.totalGold, goldToGive);
    }

    function endGame(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(
            game.players[0] == msg.sender,
            "Only game owner can end the game"
        );
        address winner = determineWinner(game);
        emit GameEnded(gameID,winner);

        playerWins[winner]++;
        game.active = false;
    }

    function placeTroops(
        uint256 gameID,
        uint256 territoryID,
        euint32 amount
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];

        // Check if the player owns the territory
        TFHE.optReq(TFHE.eq(game.territoryOwners[territoryID], player.index));

        // Check if the player has enough troops to place
        TFHE.optReq(TFHE.ge(player.totalTroops, amount));

        // Deduct the troops from the player's total
        player.totalTroops = TFHE.sub(player.totalTroops, amount);

        // Place the troops on the territory
        game.territoryInfo[territoryID].troopsHere = TFHE.add(
            game.territoryInfo[territoryID].troopsHere,
            amount
        );
    }

    function isNeighbor(
        uint256 gameID,
        uint8 to,
        uint8 from
    ) internal view returns (bool) {
        GameState storage game = games[gameID];
        Territory storage fromTerritory = game.territoryInfo[from];

        for (uint256 i = 0; i < fromTerritory.neighbors.length; i++) {
            if (fromTerritory.neighbors[i] == to) {
                return true;
            }
        }

        return false;
    }

    function playerOwnsTerritory(
        Player storage player,
        uint256 territoryID,
        uint256 gameID
    ) internal view returns (ebool) {
        GameState storage game = games[gameID];
        return TFHE.eq(game.territoryOwners[territoryID], player.index);
    }

    function resolveBattle(
        GameState storage game,
        uint256 from,
        uint256 to,
        euint32 amount
    ) internal {
        Player storage attacker = game.playerInfo[
            game.players[game.currentTurn]
        ];
        euint32 attackerTroops = amount;
        euint32 defenderTroops = game.territoryInfo[to].troopsHere;

        euint32 attackerKills = TFHE.div(
            TFHE.mul(attackerTroops, TFHE.randEuint32(600)),
            1000
        );
        euint32 defenderKills = TFHE.div(
            TFHE.mul(defenderTroops, TFHE.randEuint32(700)),
            1000
        );

        attackerTroops = TFHE.sub(
            attackerTroops,
            TFHE.min(attackerTroops, defenderKills)
        );

        defenderTroops = TFHE.sub(
            defenderTroops,
            TFHE.min(defenderTroops, attackerKills)
        );

        //If defenderTroops ==0, then remaining attackerTroops take over
        //If defenderTroops > 0, then remaining attacker troops go back to from & defenders stay
        ebool advance = TFHE.eq(defenderTroops, TFHE.asEuint8(0));
        game.territoryOwners[to] = TFHE.cmux(
            advance,
            attacker.index,
            game.territoryOwners[to]
        );
        // Update the source territory troops
        game.territoryInfo[to].troopsHere = TFHE.cmux(
            advance,
            attackerTroops,
            defenderTroops
        );
        game.territoryInfo[from].troopsHere = TFHE.cmux(
            advance,
            game.territoryInfo[to].troopsHere, //unchanged if the troops move away
            TFHE.add(game.territoryInfo[to].troopsHere, attackerTroops) //Add the surviving troops to the from
        );
    }

    function determineWinner(
        GameState storage game
    ) internal view returns (address) {
        address winner;
        uint256 maxTerritories = 0;
        uint256[] memory territoryCounts = new uint256[](game.players.length);

        for (uint256 i = 0; i < 42; i++) {
            euint8 ownerIndex = game.territoryOwners[i];
            territoryCounts[TFHE.decrypt(ownerIndex)]++;
        }

        for (uint256 i = 0; i < game.players.length; i++) {
            if (territoryCounts[i] > maxTerritories) {
                maxTerritories = territoryCounts[i];
                winner = game.players[i];
            }
        }
        return winner;
    }

    function viewTerritory(
    uint256 gameID,
    uint256 territoryID,
    bytes32 publicKey,
    bytes calldata signature
)
    public
    view
    onlySignedPublicKey(publicKey, signature)
    returns (bytes memory troopsHere, bytes memory owner)
{
    GameState storage game = games[gameID];

    // Check if the player owns the territory
    // Check if the player owns any neighboring territories
    // Determine if the player can view the territory
    ebool canLook = canPlayerLook(game,territoryID,game.playerInfo[msg.sender]);

    // Get the encrypted information
    (troopsHere, owner) = getTerritoryInfo(game, territoryID, canLook, publicKey);

}
function canPlayerLook(GameState storage game,uint256 territoryID,Player storage player) internal view returns(ebool){
        return TFHE.or(game.intel[territoryID][msg.sender],TFHE.or(TFHE.eq(game.territoryOwners[territoryID], player.index), checkNeighborOwnership(game, player, territoryID)));

}
function checkNeighborOwnership(
    GameState storage game,
    Player storage player,
    uint256 territoryID
) internal view returns (ebool) {
    Territory storage territory = game.territoryInfo[territoryID];
    euint8 neighBorOwnedCount = TFHE.asEuint8(0);
    uint256[] memory neighbors = territory.neighbors;

    for (uint256 i = 0; i < neighbors.length; i++) {
        euint8 neighborOwnerIndex = game.territoryOwners[neighbors[i]];
        ebool userOwns = TFHE.eq(neighborOwnerIndex, player.index);
        neighBorOwnedCount = TFHE.cmux(
            userOwns,
            TFHE.add(neighBorOwnedCount, 1),
            neighBorOwnedCount
        );
    }

    return TFHE.gt(neighBorOwnedCount, 0);
}

function getTerritoryInfo(
    GameState storage game,
    uint256 territoryID,
    ebool canLook,
    bytes32 publicKey
) internal view returns (bytes memory troopsHere, bytes memory owner) {
    euint32 troopsThere = TFHE.cmux(
        canLook,
        game.territoryInfo[territoryID].troopsHere,
        TFHE.asEuint32(0)
    );
    euint8 ownerIndexEncryp = TFHE.cmux(
        canLook,
         game.territoryOwners[territoryID],
        TFHE.asEuint8(99)
    );

    troopsHere = TFHE.reencrypt(troopsThere, publicKey, 0);
    owner = TFHE.reencrypt(ownerIndexEncryp, publicKey, 99);

    return (troopsHere, owner);
}

}
