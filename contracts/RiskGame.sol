// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";
import "./RiskStructs.sol";

contract RiskGame {
    using TFHE for uint256;
    uint256 public gameCounter;
    mapping(uint256 => GameState) public games;
    mapping(address => uint256) public playerWins;
    uint256 constant troopStart = 5;
    uint256 constant goldStart = 10;

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
        chosenGame.playerInfo[msg.sender].ownedTerritories = [
            TFHE.asEuint32(0),
            TFHE.asEuint32(0)
        ];
        chosenGame.playerInfo[msg.sender].totalGold = goldStart.asEuint32();
    }

    function randomlySelect() internal {
        //UwU
    }

    function startGame(uint256 gameID) public {
        require(
            games[gameID].players[0] == msg.sender,
            "Only game owner can start the game"
        );
        games[gameID].currentTurn = 0;
    }

    function endTurn(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(game.players[game.currentTurn] == msg.sender, "Not your turn");
        game.currentTurn = (game.currentTurn + 1) % game.players.length;
    }

    function moveTroops(
        uint256 gameID,
        uint256 from,
        uint256 to,
        euint32 amount
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        Territory storage source = game.territoryInfo[from];
        Territory storage target = game.territoryInfo[to];
        TFHE.optReq(TFHE.gt(1, source.troopsHere));
        TFHE.optReq(TFHE.le(amount, TFHE.sub(source.troopsHere, 1))); //"Not enough troops"
        require(isNeighbor(from, to), "Territories not neighbors");
        TFHE.optReq(playerOwnsTerritory(player, from)); //Player must own territory

        if (TFHE.decrypt(playerOwnsTerritory(player, to))) {
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

    function useCard(uint256 gameID, Cards cardType, uint256 territory) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];

        TFHE.optReq(TFHE.ge(7, player.cardCount[cardType])); //Player needs 7 cards

        if (cardType == Cards.GARRISON) {
            player.totalTroops = TFHE.add(
                player.totalTroops,
                TFHE.asEuint32(10)
            );
        } else if (cardType == Cards.ARTILLERY) {
            // Implement ARTILLERY logic
        } else if (cardType == Cards.BAMBA) {
            // Implement BAMBA logic
        } else if (cardType == Cards.INTEL) {
            // Implement INTEL logic
        }

        player.cardCount[cardType] = TFHE.sub(player.cardCount[cardType], 7);
    }

    function declareVictory(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(game.players.length == 1, "Game not finished");
        playerWins[game.players[0]]++;
    }

    function endGame(uint256 gameID) public {
        GameState storage game = games[gameID];
        require(
            game.players[0] == msg.sender,
            "Only game owner can end the game"
        );
        address winner = determineWinner(game);
        playerWins[winner]++;
        game.active = false;
    }

    function isNeighbor(uint256 from, uint256 to) internal view returns (bool) {
        // Implement neighbor check logic
    }

    function playerOwnsTerritory(
        Player storage player,
        uint256 territoryID
    ) internal view returns (ebool) {
        // Implement territory ownership check
    }

    function resolveBattle(
        GameState storage game,
        uint256 from,
        uint256 to,
        euint32 amount
    ) internal {
        // Implement battle resolution logic
    }

    function determineWinner(
        GameState storage game
    ) internal view returns (address) {
        // Implement winner determination logic
    }
}
