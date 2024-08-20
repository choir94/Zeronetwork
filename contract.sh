#!/bin/bash

BOLD_PINK='\033[1;35m'
RESET_COLOR='\033[0m'

install_node() {
  echo -e "${BOLD_PINK}Installing NVM...${RESET_COLOR}"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  echo -e "${BOLD_PINK}Installing Node.js version 20...${RESET_COLOR}"
  nvm install 20
  nvm use 20
}

if ! command -v node &> /dev/null; then
  echo -e "${BOLD_PINK}Node.js is not installed. Installing now...${RESET_COLOR}"
  install_node
elif [[ "$(node -v)" != "v20."* ]]; then
  echo -e "${BOLD_PINK}Node.js version is not 20. Installing the correct version...${RESET_COLOR}"
  install_node
else
  echo -e "${BOLD_PINK}Node.js is already installed with the correct version.${RESET_COLOR}"
fi

echo -e "${BOLD_PINK}Setting up Hardhat project (May take 2-3 mins)...${RESET_COLOR}"
echo
npm install -D @matterlabs/hardhat-zksync-deploy hardhat zksync-ethers ethers > /dev/null 2>&1
npm install -D @matterlabs/hardhat-zksync-solc > /dev/null 2>&1
npm install dotenv > /dev/null 2>&1
npx hardhat
echo
read -p "Enter your private key (without 0x): " PRIVATE_KEY
echo
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env


rm -f contracts/Lock.sol
mkdir -p contracts
cat <<EOL > contracts/SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint private number;

    // Function to set the number
    function setNumber(uint _number) public {
        number = _number;
    }

    // Function to get the number
    function getNumber() public view returns (uint) {
        return number;
    }
}
EOL

rm -f hardhat.config.ts
cat <<EOL > hardhat.config.ts
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-deploy";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  zksolc: {
  },
  solidity: {
    version: "0.8.17",
  },
  defaultNetwork: "zeroTestnet",
  networks: {
    zeroTestnet: {
      url: "https://rpc.zerion.io/v1/zero-sepolia",
      ethNetwork: "sepolia",
      zksync: true,
    },
  },
};
export default config;
EOL

mkdir -p deploy
cat <<EOL > deploy/deploy-simple-storage.ts
import { Wallet } from "zksync-ethers";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import dotenv from "dotenv";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

if (!PRIVATE_KEY) {
  throw new Error("Wallet private key is not configured in .env file!");
}

// An example of a deploy script
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(\`Running deploy script for the SimpleStorage contract\`);

  // Initialize the wallet.
  const wallet = new Wallet(PRIVATE_KEY);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("SimpleStorage");

  // Estimate contract deployment fee
  const deploymentFee = await deployer.estimateDeployFee(artifact, []);

  const parsedFee = ethers.formatEther(deploymentFee);
  console.log(\`The deployment is estimated to cost \${parsedFee} ETH\`);

  // Deploy contract
  const simpleStorageContract = await deployer.deploy(artifact, []);

  // Show the contract info.
  const contractAddress = await simpleStorageContract.getAddress();
  console.log(\`\${artifact.contractName} was deployed to \${contractAddress}\`);
}
EOL

echo -e "${BOLD_PINK}Compiling Contract...${RESET_COLOR}"
echo
npx hardhat compile
echo
echo -e "${BOLD_PINK}Deploying Contract on Zero Network...${RESET_COLOR}"
echo
npx hardhat deploy-zksync --network zeroTestnet
echo
echo -e "${BOLD_PINK}Join airdrop node t.me/airdrop_node on tele${RESET_COLOR}"
echo
