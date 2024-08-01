# Hardhat TypeScript Project with FHE-based Fog of War

This project is a Hardhat-based smart contract development environment using TypeScript. It utilizes Hardhat Deploy for deployment management and includes support for the Inco testnet. The project implements a unique fog of war mechanic using Fully Homomorphic Encryption (FHE).

## Key Features

- Smart contract development with Hardhat and TypeScript
- Deployment management using Hardhat Deploy
- Integration with Inco testnet
- FHE-based fog of war mechanic
  - Players can only view territory adjacent to their current position
  - Enhances strategic gameplay through limited visibility

## Prerequisites

- Node.js (version 12 or later)
- Yarn package manager

## Installation

To install the project dependencies, run:

```bash
yarn install
```

## Testing

To run the test suite, use:

```bash
npx hardhat test
```

## Deployment

This project uses Hardhat Deploy for managing deployments. To deploy to the Inco testnet:

1. Ensure you have configured your `.env` file with the necessary network details and private keys.
2. Run the deployment command:

```bash
npx hardhat deploy --network inco
```

## Inco Testnet

This project is configured to work with the Inco testnet. Ensure you have the correct RPC URL, chain ID, and private key configured in your Hardhat config file.

## Fog of War Mechanic

The protocol implements a fog of war mechanic using Fully Homomorphic Encryption (FHE). This feature limits players' visibility to only the territory adjacent to their current position. This adds a layer of strategy and uncertainty to the gameplay, as players must make decisions based on limited information.


## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
