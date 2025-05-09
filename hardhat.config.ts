import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { configDotenv } from "dotenv";

configDotenv();
const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    arbi: {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
  },
};

export default config;
