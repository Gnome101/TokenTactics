import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect, assert } from "chai";
//@ts-ignore
import { ethers, deployments, userConfig } from "hardhat";
import { AbiCoder, Contract, Signer } from "ethers";
import { EncryptedERC20 } from "../typechain-types/contracts/EncryptedERC20";
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
  let EncryptedERC20: EncryptedERC20;
  let instance: FhevmInstance;
  let signers: Signers;

  beforeEach(async () => {
    accounts = (await ethers.getSigners()) as unknown as SignerWithAddress[]; // could also do with getNamedAccounts
    signers = await getSigners(ethers);
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["all"]);
    const testContract = (await deployments.get(
      "EncryptedERC20"
    )) as Deployment;

    EncryptedERC20 = (await ethers.getContractAt(
      "EncryptedERC20",
      testContract.address
    )) as unknown as EncryptedERC20;

    instance = await createInstances(
      EncryptedERC20.target.toString(),
      ethers,
      deployer
    );
  });

  it("all contracts are launched", async () => {
    const encryptedAmount = instance.encrypt32(1000);
    // const tx = await EncryptedERC20.mint(encryptedAmount);
    const transaction = await createTransaction(
      EncryptedERC20.mint,
      encryptedAmount
    );
    await transaction.wait();
    const token = instance.getPublicKey(EncryptedERC20.target.toString()) || {
      signature: "",
      publicKey: "",
    };
    const encryptedBalance = await EncryptedERC20.balanceOf(
      token.publicKey,
      token.signature
    );
    // Decrypt the balance
    const balance = instance.decrypt(
      EncryptedERC20.target.toString(),
      encryptedBalance
    );
    console.log(encryptedBalance, balance);
    expect(balance).to.equal(1000);
  });
});
