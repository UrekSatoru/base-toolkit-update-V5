require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const accounts = PRIVATE_KEY ? [PRIVATE_KEY] : [];

module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    base: {
      url: "https://mainnet.base.org",
      chainId: 8453,
      accounts,
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      chainId: 84532,
      accounts,
    },
  },
};
