#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

BOLD_LIGHT_BLUE='\033[1;36m'  # Warna biru muda tebal
RESET_COLOR='\033[0m'

install_node() {
  echo -e "${BOLD_LIGHT_BLUE}Menginstal NVM...${RESET_COLOR}"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  echo -e "${BOLD_LIGHT_BLUE}Menginstal Node.js versi 20...${RESET_COLOR}"
  nvm install 20
  nvm use 20
}

if ! command -v node &> /dev/null; then
  echo -e "${BOLD_LIGHT_BLUE}Node.js belum terinstal. Menginstal sekarang...${RESET_COLOR}"
  install_node
elif [[ "$(node -v)" != "v20."* ]]; then
  echo -e "${BOLD_LIGHT_BLUE}Versi Node.js bukan 20. Menginstal versi yang benar...${RESET_COLOR}"
  install_node
else
  echo -e "${BOLD_LIGHT_BLUE}Node.js sudah terinstal dengan versi yang benar.${RESET_COLOR}"
fi

echo -e "${BOLD_LIGHT_BLUE}Menyiapkan proyek Hardhat (Dapat memakan waktu 2-3 menit)...${RESET_COLOR}"
echo
npm install -D @matterlabs/hardhat-zksync-deploy hardhat zksync-ethers ethers > /dev/null 2>&1
npm install -D @matterlabs/hardhat-zksync-solc > /dev/null 2>&1
npm install dotenv > /dev/null 2>&1
npx hardhat
echo
read -p "Masukkan private key Anda (tanpa 0x): " PRIVATE_KEY
echo
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env

rm -f contracts/Lock.sol
mkdir -p contracts
cat <<EOL > contracts/SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint private number;

    // Fungsi untuk menetapkan angka
    function setNumber(uint _number) public {
        number = _number;
    }

    // Fungsi untuk mendapatkan angka
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
  throw new Error("Private key wallet tidak dikonfigurasi di file .env!");
}

// Contoh skrip deployment
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(\`Menjalankan skrip deployment untuk kontrak SimpleStorage\`);

  // Inisialisasi wallet.
  const wallet = new Wallet(PRIVATE_KEY);

  // Buat objek deployer dan muat artifact dari kontrak yang ingin Anda deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("SimpleStorage");

  // Perkiraan biaya deployment kontrak
  const deploymentFee = await deployer.estimateDeployFee(artifact, []);

  const parsedFee = ethers.formatEther(deploymentFee);
  console.log(\`Biaya perkiraan deployment adalah \${parsedFee} ETH\`);

  // Deploy kontrak
  const simpleStorageContract = await deployer.deploy(artifact, []);

  // Tampilkan informasi kontrak.
  const contractAddress = await simpleStorageContract.getAddress();
  console.log(\`\${artifact.contractName} telah di-deploy ke \${contractAddress}\`);
}
EOL

echo -e "${BOLD_LIGHT_BLUE}Mengompilasi Kontrak...${RESET_COLOR}"
echo
npx hardhat compile
echo
echo -e "${BOLD_LIGHT_BLUE}Mendeploy Kontrak pada Jaringan Zero...${RESET_COLOR}"
echo
npx hardhat deploy-zksync --network zeroTestnet
echo
echo -e "${BOLD_LIGHT_BLUE}Gabung airdrop node t.me/airdrop_node di tele${RESET_COLOR}"
echo
