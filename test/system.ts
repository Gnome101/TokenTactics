import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect, assert } from "chai";
//@ts-ignore
import { ethers, deployments, userConfig } from "hardhat";
import { AbiCoder, AddressLike, Contract, Signer } from "ethers";
import { RiskGame } from "../typechain-types/contracts/RiskGame";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/dist/src/signer-with-address";
import { Address, Deployment } from "hardhat-deploy/dist/types";
import { createInstances } from "./instance";
import { FhevmInstances } from "./types";
import { Signers, getSigners } from "./signers";
import { FhevmInstance } from "fhevmjs";
import { createTransaction } from "./utils";
import("tfhe/tfhe");
describe("System test", function () {
  let accounts: SignerWithAddress[];
  let deployer: SignerWithAddress;
  let user: SignerWithAddress;
  let deployerRisk: RiskGame;
  let userRisk: RiskGame;

  let deployerInstance: FhevmInstance;
  let userInstance: FhevmInstance;

  let signers: Signers;

  beforeEach(async () => {
    accounts = (await ethers.getSigners()) as unknown as SignerWithAddress[]; // could also do with getNamedAccounts
    signers = await getSigners(ethers);
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["all"]);
    const riskContract = (await deployments.get("RiskGame")) as Deployment;

    deployerRisk = (await ethers.getContractAt(
      "RiskGame",
      riskContract.address,
      deployer
    )) as unknown as RiskGame;

    userRisk = (await ethers.getContractAt(
      "RiskGame",
      riskContract.address,
      user
    )) as unknown as RiskGame;

    deployerInstance = await createInstances(
      deployerRisk.target.toString(),
      ethers,
      deployer
    );
    userInstance = await createInstances(
      userRisk.target.toString(),
      ethers,
      user
    );
  });

  it("contract was deployed", async () => {
    assert.ok(deployerRisk.target.toString());
    assert.ok(userRisk.target.toString());
  });
  it("game process from create, to join, to start, to validate now", async () => {
    console.log(deployerRisk.target, user.address, deployer.address);
    // Create a game
    const gameID = await deployerRisk.gameCounter();
    const tx1 = await deployerRisk.createGame();
    // // Join the game
    await tx1.wait();
    const tx2 = await userRisk.joinGame(gameID);
    await tx2.wait();

    // // Start the game
    const tx3 = await deployerRisk.startGame(gameID);
    await tx3.wait();
    const token = deployerInstance.getPublicKey(
      deployerRisk.target.toString()
    ) || {
      signature: "",
      publicKey: "",
    };
    const encryptedBalance = await deployerRisk.viewBalance(
      gameID,
      token.publicKey,
      token.signature
    );
    const balance = deployerInstance.decrypt(
      deployerRisk.target.toString(),
      encryptedBalance
    );

    const encryptedSoldiers = await deployerRisk.viewTotalSoldiers(
      gameID,
      token.publicKey,
      token.signature
    );

    const totalSoldiers = deployerInstance.decrypt(
      deployerRisk.target.toString(),
      encryptedSoldiers
    );

    console.log("balacnce", balance.toString());
    assert.equal(balance.toString(), "15"); //10 initial + 5 from first round
    assert.equal(totalSoldiers.toString(), "5");

    const result = (await returnTerritories(
      deployerInstance,
      deployerRisk,
      deployer.address,
      gameID
    )) as unknown as Territory[];
    console.log(result);
    if (result == undefined) throw "AA";
    // Move troops from one territory to another
    //@ts-ignore
    const fromTerritory = result.find((t) => t.ours).id;
    //@ts-ignore
    const toTerritory = fromTerritory + 1; //result.find((t) => t.ours && t.id !== fromTerritory).id;
    const troopsHereBefore = await getTerritoryInfo(
      deployerInstance,
      deployerRisk,
      fromTerritory,
      gameID
    );
    console.log(`Before this place has ${troopsHereBefore.troops} troops`);
    const amount = 2;

    console.log(`Deploying ${amount} at ${fromTerritory}`);
    const deployTx = await deployerRisk.deployTroops(
      gameID,
      deployerInstance.encrypt32(fromTerritory),
      deployerInstance.encrypt32(amount)
    );
    await deployTx.wait();
    const troopsHereAfter = await getTerritoryInfo(
      deployerInstance,
      deployerRisk,
      fromTerritory,
      gameID
    );
    console.log(`Now this place has ${troopsHereAfter.troops} troops`);
    console.log(`Moving troops from ${fromTerritory} to ${toTerritory}...`);
    const moveTx = await deployerRisk.moveTroops(
      gameID,
      deployerInstance.encrypt32(fromTerritory),
      deployerInstance.encrypt32(toTerritory),
      deployerInstance.encrypt32(1)
    );
    await moveTx.wait();
    const troopsHereAfterAfter = await getTerritoryInfo(
      deployerInstance,
      deployerRisk,
      fromTerritory,
      gameID
    );
    console.log(`Now this place has ${troopsHereAfterAfter.troops} troops`);
    // const updatedTerritories = await returnTerritories(
    //   deployerInstance,
    //   deployerRisk,
    //   gameID
    // );
    // console.log(updatedTerritories);

    // // Place additional troops in a territory
    // const placeTx = await deployerRisk.placeTroops(
    //   gameID,
    //   fromTerritory,
    //   deployerInstance.encrypt(2)
    // );
    // await placeTx.wait();

    // const finalTerritories = await returnTerritories(
    //   deployerInstance,
    //   deployerRisk,
    //   gameID
    // );
    // console.log(finalTerritories);

    // assert(
    //   finalTerritories.some((t) => t.id === fromTerritory && t.troops === 3)
    // );
  });
});
function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function getTerritoryInfo(
  userInstance: FhevmInstance,
  riskGame: RiskGame,
  tID: number,
  gameID: bigint
): Promise<Territory> {
  const token = userInstance.getPublicKey(riskGame.target.toString()) || {
    signature: "",
    publicKey: "",
  };
  const encryptedTerritory = await riskGame.viewTerritory(
    gameID,
    BigInt(tID),
    token.publicKey,
    token.signature
  );

  const soldierCount = userInstance.decrypt(
    riskGame.target.toString(),
    encryptedTerritory[0]
  );
  const owner = userInstance.decrypt(
    riskGame.target.toString(),
    encryptedTerritory[1]
  );
  // console.log(tID, owner);
  if (owner.toString() === "99") {
    throw "cant view"; // We can't view this so skip to the next territory
  }
  let ownerAddress = ethers.ZeroAddress;
  if (owner.toString() != "98") {
    //If its not 98, then someone owns it
    ownerAddress = await riskGame.getPlayer(gameID, BigInt(owner));
  }

  const territory: Territory = {
    id: tID,
    owner: ownerAddress,
    troops: parseInt(soldierCount.toString(), 10),
    //@ts-ignore
    ours: ownerAddress === riskGame.runner.address,
  };
  return territory;
}

async function returnTerritories(
  userInstance: FhevmInstance,
  riskGame: RiskGame,
  userAddress: string,
  gameID: bigint
): Promise<Territory[]> {
  const token = userInstance.getPublicKey(riskGame.target.toString()) || {
    signature: "",
    publicKey: "",
  };

  const territories: Territory[] = [];

  for (let tID = 0; tID < 42; tID++) {
    const encryptedTerritory = await riskGame.viewTerritory(
      gameID,
      BigInt(tID),
      token.publicKey,
      token.signature
    );

    const soldierCount = userInstance.decrypt(
      riskGame.target.toString(),
      encryptedTerritory[0]
    );
    const owner = userInstance.decrypt(
      riskGame.target.toString(),
      encryptedTerritory[1]
    );
    // console.log(tID, owner);
    if (owner.toString() === "99") {
      continue; // We can't view this so skip to the next territory
    }
    let ownerAddress = ethers.ZeroAddress;
    if (owner.toString() != "98") {
      //If its not 98, then someone owns it
      ownerAddress = await riskGame.getPlayer(gameID, BigInt(owner));
    }
    // console.log(ownerAddress, userAddress);
    const territory: Territory = {
      id: tID,
      owner: ownerAddress,
      troops: parseInt(soldierCount.toString(), 10),
      //@ts-ignore
      ours: ownerAddress == userAddress,
    };

    territories.push(territory);
  }

  return territories;
}

export interface Territory {
  id: number;
  owner: AddressLike;
  troops: number;
  ours: boolean;
}
