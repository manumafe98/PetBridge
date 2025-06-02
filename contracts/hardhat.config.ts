import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import * as dotenv from "dotenv";

dotenv.config();

const { PRIVATE_KEY } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.30",
  networks: {
    westendHub: {
      url: 'https://westend-asset-hub-eth-rpc.polkadot.io',
      accounts: [`0x${PRIVATE_KEY}`],
    }
  }
};

export default config;
