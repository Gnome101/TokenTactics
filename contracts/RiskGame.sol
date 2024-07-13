// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;
import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";
import "./RiskStructs.sol";
import "hardhat/console.sol";

event Garrison(uint256 gameID);
event Artillery(uint256 gameID, euint32 territoryID);
event Bamba(uint256 gameID, euint32 territoryID);
event Intel(uint256 gameID, euint32 territoryID);

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

    mapping(euint32 => euint32[]) private neighborsMap;
 function toEuint32Array(uint256[6] memory input) internal pure returns (euint32[] memory output) {
        for (uint256 i = 0; i < 6; i++) {
            output[i] = input[i].asEuint32();
        }
    }
    constructor() EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;
        neighborsMap[euint32.wrap(0)] = toEuint32Array([uint256(2), 3, 26, 0, 0, 0]);
        neighborsMap[euint32.wrap(1)] = toEuint32Array([uint256(1), 3, 4, 13, 0, 0]);
        neighborsMap[euint32.wrap(2)] = toEuint32Array([uint256(1), 2, 4, 6, 0, 0]);
        neighborsMap[euint32.wrap(3)] = toEuint32Array([uint256(2), 3, 6, 7, 5, 13]);
        neighborsMap[euint32.wrap(4)] = toEuint32Array([uint256(4), 7, 13, 0, 0, 0]);
        neighborsMap[euint32.wrap(5)] = toEuint32Array([uint256(3), 4, 7, 8, 0, 0]);
        neighborsMap[euint32.wrap(6)] = toEuint32Array([uint256(3), 4, 5, 6, 8, 0]);
        neighborsMap[euint32.wrap(7)] = toEuint32Array([uint256(6), 7, 9, 0, 0, 0]);
        neighborsMap[euint32.wrap(8)] = toEuint32Array([uint256(8), 10, 11, 0, 0, 0]);
        neighborsMap[euint32.wrap(9)] = toEuint32Array([uint256(9), 11, 12, 0, 0, 0]);
        neighborsMap[euint32.wrap(10)] = toEuint32Array([uint256(9), 10, 12, 0, 0, 0]);
        neighborsMap[euint32.wrap(11)] = toEuint32Array([uint256(10), 11, 0, 0, 0, 0]);
        neighborsMap[euint32.wrap(12)] = toEuint32Array([uint256(2), 4, 5, 14, 0, 0]);
        neighborsMap[euint32.wrap(13)] = toEuint32Array([uint256(13), 17, 15, 0, 0, 0]);
        neighborsMap[euint32.wrap(14)] = toEuint32Array([uint256(14), 17, 19, 16, 0, 0]);
        neighborsMap[euint32.wrap(15)] = toEuint32Array([uint256(15), 19, 20, 21, 22, 23]);
        neighborsMap[euint32.wrap(16)] = toEuint32Array([uint256(15), 19, 18, 0, 0, 0]);
        neighborsMap[euint32.wrap(17)] = toEuint32Array([uint256(17), 19, 20, 33, 0, 0]);
        neighborsMap[euint32.wrap(18)] = toEuint32Array([uint256(15), 17, 18, 20, 16, 0]);
        neighborsMap[euint32.wrap(19)] = toEuint32Array([uint256(18), 19, 16, 21, 34, 0]);
        neighborsMap[euint32.wrap(20)] = toEuint32Array([uint256(16), 20, 34, 29, 0, 0]);
        neighborsMap[euint32.wrap(21)] = toEuint32Array([uint256(16), 23, 30, 21, 29, 0]);
        neighborsMap[euint32.wrap(22)] = toEuint32Array([uint256(16), 22, 24, 0, 0, 0]);
        neighborsMap[euint32.wrap(23)] = toEuint32Array([uint256(23), 30, 27, 28, 25, 0]);
        neighborsMap[euint32.wrap(24)] = toEuint32Array([uint256(24), 27, 26, 0, 0, 0]);
        neighborsMap[euint32.wrap(25)] = toEuint32Array([uint256(25), 1, 31, 0, 0, 0]);
        neighborsMap[euint32.wrap(26)] = toEuint32Array([uint256(24), 26, 28, 25, 0, 0]);
        neighborsMap[euint32.wrap(27)] = toEuint32Array([uint256(30), 31, 0, 0, 0, 0]);
        neighborsMap[euint32.wrap(28)] = toEuint32Array([uint256(21), 22, 30, 40, 0, 0]);
        neighborsMap[euint32.wrap(29)] = toEuint32Array([uint256(22), 28, 29, 40, 0, 0]);
        neighborsMap[euint32.wrap(30)] = toEuint32Array([uint256(26), 28, 0, 0, 0, 0]);
        neighborsMap[euint32.wrap(31)] = toEuint32Array([uint256(18), 33, 34, 35, 0, 0]);
        neighborsMap[euint32.wrap(32)] = toEuint32Array([uint256(20), 32, 34, 21, 0, 0]);
        neighborsMap[euint32.wrap(33)] = toEuint32Array([uint256(21), 32, 33, 35, 37, 0]);
        neighborsMap[euint32.wrap(34)] = toEuint32Array([uint256(32), 34, 36, 0, 0, 0]);
        neighborsMap[euint32.wrap(35)] = toEuint32Array([uint256(35), 34, 37, 0, 0, 0]);
        neighborsMap[euint32.wrap(36)] = toEuint32Array([uint256(34), 36, 0, 0, 0, 0]);
        neighborsMap[euint32.wrap(37)] = toEuint32Array([uint256(29), 30, 39, 0, 0, 0]);
        neighborsMap[euint32.wrap(38)] = toEuint32Array([uint256(38), 40, 41, 0, 0, 0]);
        neighborsMap[euint32.wrap(39)] = toEuint32Array([uint256(39), 41, 42, 0, 0, 0]);
        neighborsMap[euint32.wrap(40)] = toEuint32Array([uint256(39), 40, 42, 0, 0, 0]);
        neighborsMap[euint32.wrap(41)] = toEuint32Array([uint256(41), 40, 0, 0, 0, 0]);

    }

    function createGame() public {
        GameState storage newGame = games[gameCounter];
        newGame.gameID = gameCounter;
        newGame.active = true;
        joinGame(gameCounter);
        gameCounter++;


    }

    function joinGame(uint256 gameID) public {
        require(games[gameID].active, "Game is not active");
        GameState storage chosenGame = games[gameID];

        chosenGame.players.push(msg.sender);
        chosenGame.playerInfo[msg.sender].playerAddress = msg.sender;
        chosenGame.playerInfo[msg.sender].totalTroops = troopStart.asEuint32();
        chosenGame.playerInfo[msg.sender].totalGold = goldStart.asEuint32();
        chosenGame.playerInfo[msg.sender].index = (chosenGame.players.length).asEuint32();
    }

    function randomlySelect(uint256 gameID) internal {
    GameState storage activeGame = games[gameID];
    address[] memory playerAddys = activeGame.players;
    uint256 playerCount = playerAddys.length;
    require(playerAddys.length == 2, "tw");
    require(playerCount > 0, "No players in the game");

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
    uint256 startPlayer = uint256(TFHE.decrypt(randomNumber)) % playerCount;
  // Randomly select a player to start

    // Assign 5 territories to each player in a round-robin manner
    for (uint256 i = 0; i < 5 * playerCount; i++) {
        uint256 currentPlayerIndex = (startPlayer + i) % playerCount;

        uint256 randIndex = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    i
                )
            )
        ) % counter;

        // Ensure randIndex is within bounds
        require(randIndex < counter, "Random index out of bounds");

        euint32 selectedTerritoryID = unassignedTerritories[randIndex].asEuint32();

        // Assign the territory to the player and place one troop there
        activeGame.territoryInfo[selectedTerritoryID].troopsHere = TFHE.asEuint32(1);
        activeGame.territoryOwners[selectedTerritoryID] = TFHE.add(currentPlayerIndex.asEuint32(),1);

        // Remove the selected territory from the unassignedTerritories array
        unassignedTerritories[randIndex] = unassignedTerritories[counter - 1];
        counter--;
    }
    // for (uint256 i = 0; i < playerCount ; i++) {
    //     for (uint j = 5 * i; j < 5 * (i + 1); j++) {
    //         // Assign the territory to the player and place one troop there
    //     activeGame.territoryInfo[j].troopsHere = TFHE.asEuint32(1);
    //     activeGame.territoryOwners[j] = TFHE.add(i.asEuint8(),1);
    //     }
        
    // }
}


    function startGame(uint256 gameID) public {
        console.log("Starting game");

        require(
            games[gameID].players[0] == msg.sender,
            "Only game owner can start the game"
        );
        GameState storage game = games[gameID];

        game.currentTurn = 0;
        randomlySelect(gameID);
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
        bytes calldata fromData,
        bytes calldata toData,
        bytes calldata amountData
    ) public {
        GameState storage game = games[gameID];
        euint32 from = TFHE.asEuint32(fromData);
        euint32 to = TFHE.asEuint32(toData);

        Territory storage source = game.territoryInfo[from];

        TFHE.optReq(TFHE.gt(1, source.troopsHere));
         euint32 amount = TFHE.asEuint32(amountData);
 
       preformChecks(false,game,amount,TFHE.sub(source.troopsHere, 1),from,to);

       removeTroopsHere(source, amount);
       addTroopsHere(game.territoryInfo[to], amount);

    }
function preformChecks(bool attack,GameState storage game,euint32 amount, euint32 troopsHereAfter,euint32 from,euint32 to)internal view {
            Player storage player = game.playerInfo[msg.sender];

        TFHE.optReq(TFHE.le(amount, troopsHereAfter)); //"Not enough troops"
        TFHE.optReq(isNeighbor( from, to));// "Territories not neighbors"
        TFHE.optReq(playerOwnsTerritory(player, from, game.gameID)); //Player must own territory
        if(attack){
        TFHE.optReq(TFHE.not(playerOwnsTerritory(player, to, game.gameID)));//Player must not own other territory
        } else {
       TFHE.optReq(TFHE.or(playerOwnsTerritory(player, to, game.gameID),TFHE.asEbool(TFHE.isInitialized(game.territoryInfo[to].troopsHere))));//Player must not own other territory

        }

      
}
      function attackTroops(
        uint256 gameID,
        bytes calldata fromData,
        bytes calldata toData,
        bytes calldata amountData
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        euint32 from = TFHE.asEuint32(fromData);
        euint32 to = TFHE.asEuint32(toData);

        Territory storage source = game.territoryInfo[from];

        TFHE.optReq(TFHE.gt(1, source.troopsHere));
         euint32 amount = TFHE.asEuint32(amountData);

              preformChecks(true,game,amount,TFHE.sub(source.troopsHere, 1),from,to);


        require(TFHE.isInitialized(game.territoryInfo[to].troopsHere), "Must be enemy player");        
    
        resolveBattle(game, from, to, amount);

    }
    function settleMovement() internal {

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
bytes calldata territoryData
    ) public {
        GameState storage game = games[gameID];
        Player storage player = game.playerInfo[msg.sender];
        euint32 cardType = TFHE.asEuint32(cardToUse);
        euint32 territoryID = TFHE.asEuint32(territoryData);
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
            ebool owns = TFHE.eq(game.territoryOwners[TFHE.asEuint32(i)], currentPlayer.index);
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
        euint32 territoryID,
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
    function getNeighbors(euint32 index) internal view returns(euint32[] memory){
        return neighborsMap[index];
    }
    function isNeighbor(
        euint32 to,
        euint32 from
    ) internal view  returns (ebool res) {
        euint32[] memory neighbors = getNeighbors(from);
        res = TFHE.asEbool(false);
        for (uint256 i = 0; i < neighbors.length; i++) {
            res =  TFHE.or(res,TFHE.eq(neighbors[i],to));           
        }

        return res;
    }

    function playerOwnsTerritory(
        Player storage player,
        euint32 territoryID,
        uint256 gameID
    ) internal view returns (ebool) {
        GameState storage game = games[gameID];
        return TFHE.eq(game.territoryOwners[territoryID], player.index);
    }

    function resolveBattle(
        GameState storage game,
        euint32 from,
        euint32 to,
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
            euint32 ownerIndex = game.territoryOwners[i.asEuint32()];
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
    function viewBalance(uint256 gameID,  bytes32 publicKey,
    bytes calldata signature)public view onlySignedPublicKey(publicKey,signature) returns(bytes memory balance) {
            GameState storage game = games[gameID];

        Player storage player = game.playerInfo[msg.sender];
        return TFHE.reencrypt(player.totalGold,publicKey,0);
    }

    function viewTotalSoldiers(uint256 gameID,  bytes32 publicKey,
    bytes calldata signature)public view onlySignedPublicKey(publicKey,signature) returns(bytes memory balance) {
            GameState storage game = games[gameID];

        Player storage player = game.playerInfo[msg.sender];
        return TFHE.reencrypt(player.totalTroops,publicKey,0);
    }
    function viewCardCount(uint256 gameID,uint256 card,  bytes32 publicKey,
    bytes calldata signature)public view onlySignedPublicKey(publicKey,signature) returns(bytes memory balance) {
            GameState storage game = games[gameID];

        Player storage player = game.playerInfo[msg.sender];
        return TFHE.reencrypt(player.cardCount[card.asEuint32()],publicKey,0);
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
    ebool canLook = canPlayerLook(game,territoryID.asEuint32(),game.playerInfo[msg.sender]);

    // Get the encrypted information
    (troopsHere, owner) = getTerritoryInfo(game, territoryID.asEuint32(), canLook, publicKey);

}

function canPlayerLook(GameState storage game,euint32 territoryID,Player storage player) internal view returns(ebool){
            require(TFHE.isInitialized(player.index), "Must be real");
        return TFHE.or(game.intel[territoryID][player.playerAddress],TFHE.or(TFHE.eq(game.territoryOwners[territoryID], player.index),checkNeighborOwnership(game,player,territoryID)));

}
function checkNeighborOwnership(
    GameState storage game,
    Player storage player,
    euint32 territoryID
) internal view returns (ebool) {
    ebool canLook = TFHE.asEbool(false);
    euint32[] memory neighbors = getNeighbors(territoryID);
    require(neighbors.length > 1, "a");
    for (uint256 i = 0; i < neighbors.length; i++) {
        if(!TFHE.isInitialized(game.territoryOwners[neighbors[i]]) ) continue;
     canLook = TFHE.or(canLook,TFHE.eq(game.territoryOwners[neighbors[i]], player.index));
    }

    return canLook;
}  
function getPlayer(uint256 gameID, uint256 index) public view returns(address) {
    GameState storage game = games[gameID];
    return game.players[index];
}

function getTerritoryInfo(
    GameState storage game,
    euint32 territoryID,
    ebool canLook,
    bytes32 publicKey
) internal view returns (bytes memory troopsHere, bytes memory owner) {
    euint32 troopsThere = TFHE.cmux(
        canLook,
        TFHE.isInitialized(game.territoryInfo[territoryID].troopsHere) ?game.territoryInfo[territoryID].troopsHere :TFHE.asEuint32(0),
        TFHE.asEuint32(0)
    );
    euint32 ownerIndexEncryp = TFHE.cmux(
        canLook,
         TFHE.isInitialized(game.territoryOwners[territoryID]) ?game.territoryOwners[territoryID] :TFHE.asEuint32(98) ,
        TFHE.asEuint32(99)
    );

    troopsHere = TFHE.reencrypt(troopsThere, publicKey, 0);
    owner = TFHE.reencrypt(ownerIndexEncryp, publicKey, 99);

    return (troopsHere, owner);
} 
   

}
