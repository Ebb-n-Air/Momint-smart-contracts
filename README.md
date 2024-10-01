# Smart Contracts Repository

This repository contains a collection of smart contracts developed for various purposes, primarily focused on NFTs, token management, and airdrop functionality. Below is an overview of the contracts and instructions on how to run and deploy them.

## Contracts Overview

1. **MomintNFT.sol**
   - An ERC721 compliant NFT contract with batch minting capabilities.
   - Supports royalties, batch management, and token burning.

2. **ERC1155.sol**
   - An ERC1155 compliant token contract with minting, pausing, and role-based access control.

3. **MomintSimpleAirdrop.sol**
   - A contract for performing simple airdrops of ERC20 tokens.

4. **main.mo (Motoko)**
   - A contract for managing entries with consumption and production power data.

5. **AIRDROP.mo (Motoko)**
   - A contract for managing airdrops on the Internet Computer platform.

## Prerequisites

- Node.js and npm
- Hardhat
- Dfinity SDK (for Motoko contracts)

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/Ebb-n-Air/Smart-Contracts.git
   cd Smart-Contracts
   ```

2. Install dependencies:
   ```
   npm install
   ```

## Running and Deploying Ethereum Contracts

1. Compile the contracts:
   ```
   npx hardhat compile
   ```

2. Run tests (if available):
   ```
   npx hardhat test
   ```

3. Deploy to a local Hardhat network:
   ```
   npx hardhat run scripts/deploy.js --network localhost
   ```

4. To deploy to a testnet or mainnet, add the network configuration to `hardhat.config.js` and run:
   ```
   npx hardhat run scripts/deploy.js --network <network-name>
   ```

## Running and Deploying Motoko Contracts

1. Start a local Internet Computer replica:
   ```
   dfx start --background
   ```

2. Deploy the Motoko contracts:
   ```
   dfx deploy
   ```

3. To interact with the deployed contracts, use the `dfx canister call` command. For example:
   ```
   dfx canister call <canister_name> <method_name> '(<arguments>)'
   ```

## Scripts

- `mint.sh`: Script for minting NFTs to specified principal IDs.
- `deploy.sh`: Script for deploying and initializing contracts on the Internet Computer.

To use these scripts:
1. Make them executable: `chmod +x mint.sh deploy.sh`
2. Run them: `./mint.sh` or `./deploy.sh`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
