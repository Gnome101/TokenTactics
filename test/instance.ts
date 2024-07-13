import type { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/dist/src/signer-with-address";

import { Signer } from "ethers";
import fhevmjs, { FhevmInstance } from "fhevmjs";
import { ethers as hethers } from "hardhat";

import { FHE_LIB_ADDRESS } from "./generated";
import { FhevmInstances } from "./types";

let publicKey: string;
let chainId: number;

export const createInstances = async (
  contractAddress: string,
  ethers: typeof hethers,
  account: SignerWithAddress
): Promise<FhevmInstance> => {
  if (!publicKey || !chainId) {
    // 1. Get chain id
    const provider = ethers.provider;

    const network = await provider.getNetwork();
    chainId = +network.chainId.toString(); // Need to be a number
    console.log("info", network, chainId);
    // Get blockchain public key
    const ret = await provider.call({
      to: "0x000000000000000000000000000000000000005d",
      // first four bytes of keccak256('fhePubKey(bytes1)') + 1 byte for library
      data: "0xd9d47bb001",
    });
    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(["bytes"], ret);
    publicKey = decoded[0];
  }

  // Create instanc

  const instance = await fhevmjs.createInstance({ chainId, publicKey });
  await generateToken(contractAddress, account, instance);
  return instance;
};

const generateToken = async (
  contractAddress: string,
  account: SignerWithAddress,
  instance: FhevmInstance
) => {
  // Generate token to decrypt
  const generatedToken = instance.generatePublicKey({
    verifyingContract: contractAddress,
  });

  // Use TypedDataEncoder for signing
  console.log(account);
  const signature = await account.signTypedData(
    generatedToken.eip712.domain,
    { Reencrypt: generatedToken.eip712.types.Reencrypt }, // Need to remove EIP712Domain from types
    generatedToken.eip712.message
  );
  instance.setSignature(contractAddress, signature);
};
