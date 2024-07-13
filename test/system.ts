import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect, assert } from "chai";
//@ts-ignore
import { ethers, deployments, userConfig } from "hardhat";
import { AbiCoder, Contract, Signer } from "ethers";
// import { EncryptedERC20 } from "../typechain-types/contracts/EncryptedERC20";
import { RiskGame } from "../typechain-types/contracts/RiskGame";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/dist/src/signer-with-address";
import { Deployment } from "hardhat-deploy/dist/types";
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
  let RiskGame: RiskGame;
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

    RiskGame = (await ethers.getContractAt(
      "RiskGame",
      riskContract.address
    )) as unknown as RiskGame;

    deployerInstance = await createInstances(
      RiskGame.target.toString(),
      ethers,
      deployer
    );
    userInstance = await createInstances(
      RiskGame.target.toString(),
      ethers,
      deployer
    );
  });
});
