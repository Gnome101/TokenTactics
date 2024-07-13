import { ethers, providers, Signer } from "ethers";
import fhevmjs, { FhevmInstance } from "fhevmjs";

const FHE_LIB_ADDRESS = "0x000000000000000000000000000000000000005d"; // Replace with the actual FHE library address

let instance: FhevmInstance | undefined;
let publicKey: string | undefined;
let chainId: number | undefined;

export const getFhevmInstance = async (
  provider: providers.Provider
): Promise<FhevmInstance> => {
  if (!instance) {
    if (!publicKey || !chainId) {
      const network = await provider.getNetwork();
      chainId = +network.chainId.toString(); // Convert to number

      // Get blockchain public key
      const ret = await provider.call({
        to: FHE_LIB_ADDRESS,
        data: "0xd9d47bb001", // keccak256('fhePubKey(bytes1)') + 1 byte for library
      });

      const decoded = ethers.defaultAbiCoder.decode(["bytes"], ret);
      publicKey = decoded[0];
      console.log("Retrieved public key:", publicKey);
    }

    // Validate the public key
    if (!publicKey || publicKey.length !== expectedLength) {
      // Replace expectedLength with the actual length
      throw new Error("Invalid public key retrieved");
    }

    // Create the FHEVM instance
    try {
      instance = await fhevmjs.createInstance({ chainId, publicKey });
      console.info("FHEVM instance created");
    } catch (error) {
      console.error("Error creating FHEVM instance:", error);
      throw error;
    }
  }
  return instance;
};

export const generateToken = async (
  contractAddress: string,
  signer: Signer,
  instance: FhevmInstance
): Promise<void> => {
  const generatedToken = instance.generatePublicKey({
    verifyingContract: contractAddress,
  });

  const signature = await signer._signTypedData(
    generatedToken.eip712.domain,
    { Reencrypt: generatedToken.eip712.types.Reencrypt }, // Remove EIP712Domain from types
    generatedToken.eip712.message
  );
  instance.setSignature(contractAddress, signature);
};
