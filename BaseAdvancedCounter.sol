BASE L2 WEB3 ADVANCED STARTER (SOLIDITY + HARDHAT + FRONTEND)
=============================================================

This TXT contains a more advanced, self-contained starter to build on **Base** (L2 by Coinbase).

It includes:
- 1 advanced smart contract (Solidity)
- Hardhat config targeting Base + Base Sepolia
- A deploy script
- A minimal frontend (HTML + JS with ethers v6)
- A basic Hardhat test

You can copy/paste each block into your repo files.

--------------------------------------------------
1. SMART CONTRACT (BaseAdvancedCounter on Base)
--------------------------------------------------

File: contracts/BaseAdvancedCounter.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Advanced counter contract for Base L2
/// @notice Counter with min/max limits, pause, reset and ownership
contract BaseAdvancedCounter {
    uint256 public value;
    uint256 public minValue;
    uint256 public maxValue;
    address public owner;
    bool public paused;
    uint256 public lastUpdated;

    event Increment(address indexed caller, uint256 newValue);
    event Decrement(address indexed caller, uint256 newValue);
    event Reset(address indexed caller, uint256 newValue);
    event LimitsChanged(uint256 minValue, uint256 maxValue);
    event Paused(bool status);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    /// @param _initialValue initial value of the counter
    /// @param _minValue     minimum allowed value
    /// @param _maxValue     maximum allowed value
    constructor(
        uint256 _initialValue,
        uint256 _minValue,
        uint256 _maxValue
    ) {
        require(_minValue <= _initialValue, "Initial < min");
        require(_initialValue <= _maxValue, "Initial > max");
        require(_minValue < _maxValue, "Invalid bounds");

        owner = msg.sender;
        value = _initialValue;
        minValue = _minValue;
        maxValue = _maxValue;
        lastUpdated = block.timestamp;
    }

    /// @notice Increment the counter by a given amount
    /// @param _amount the amount to add
    function increment(uint256 _amount) external notPaused {
        require(_amount > 0, "Amount = 0");

        uint256 newValue = value + _amount;
        require(newValue <= maxValue, "Above max");

        value = newValue;
        lastUpdated = block.timestamp;

        emit Increment(msg.sender, newValue);
    }

    /// @notice Decrement the counter by a given amount
    /// @param _amount the amount to subtract
    function decrement(uint256 _amount) external notPaused {
        require(_amount > 0, "Amount = 0");
        require(_amount <= value, "Underflow");

        uint256 newValue = value - _amount;
        require(newValue >= minValue, "Below min");

        value = newValue;
        lastUpdated = block.timestamp;

        emit Decrement(msg.sender, newValue);
    }

    /// @notice Reset the counter to zero
    function reset() external onlyOwner {
        value = 0;
        lastUpdated = block.timestamp;
        emit Reset(msg.sender, 0);
    }

    /// @notice Change the min/max limits
    /// @dev Current value must stay within the new bounds
    function setLimits(uint256 _minValue, uint256 _maxValue) external onlyOwner {
        require(_minValue <= value, "Current < new min");
        require(value <= _maxValue, "Current > new max");
        require(_minValue < _maxValue, "Invalid bounds");

        minValue = _minValue;
        maxValue = _maxValue;

        emit LimitsChanged(_minValue, _maxValue);
    }

    /// @notice Transfer contract ownership to a new address
    /// @param _newOwner new owner address
    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");

        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice Pause or unpause all state-changing operations
    /// @param _status true to pause, false to unpause
    function setPaused(bool _status) external onlyOwner {
        paused = _status;
        emit Paused(_status);
    }

    /// @notice Returns true if the counter is currently at its maximum value
    function isAtMax() external view returns (bool) {
        return value == maxValue;
    }

    /// @notice Returns true if the counter is currently at its minimum value
    function isAtMin() external view returns (bool) {
        return value == minValue;
    }
}

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/**
 * You MUST set PRIVATE_KEY in a .env file:
 * PRIVATE_KEY=0xyourprivatekey...
 *
 * IMPORTANT:
 * - Never commit your .env file to GitHub.
 * - Add ".env" to your .gitignore file.
 */
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

const hre = require("hardhat");

async function main() {
  // Initial configuration
  const initialValue = 0;
  const minValue = 0;
  const maxValue = 1_000_000;

  // Get contract factory
  const Factory = await hre.ethers.getContractFactory("BaseAdvancedCounter");

  // Deploy contract
  const counter = await Factory.deploy(initialValue, minValue, maxValue);

  await counter.waitForDeployment();

  const address = await counter.getAddress();
  console.log("BaseAdvancedCounter deployed to:", address);

  // Optional: read initial state
  const value = await counter.value();
  const min = await counter.minValue();
  const max = await counter.maxValue();
  console.log("Initial value:", value.toString());
  console.log("Min / Max:", min.toString(), "/", max.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>BaseAdvancedCounter dApp (Base L2)</title>
</head>
<body>
  <h1>BaseAdvancedCounter dApp</h1>

  <button id="connect">Connect Wallet</button>
  <p>Account: <span id="account">Not connected</span></p>

  <h2>Counter</h2>
  <p>Current value: <span id="value">0</span></p>
  <p>Min: <span id="min">0</span> | Max: <span id="max">0</span></p>
  <p>Last updated: <span id="lastUpdated">-</span></p>
  <p>Status: <span id="status">Unknown</span></p>

  <input id="amount" type="number" value="1" min="1" />
  <button id="increment">Increment</button>
  <button id="decrement">Decrement</button>

  <script src="https://cdn.jsdelivr.net/npm/ethers@6.13.0/dist/ethers.umd.min.js"></script>
  <script src="./app.js"></script>
</body>
</html>


// REPLACE with your deployed contract address on Base:
const CONTRACT_ADDRESS = "0xYOUR_CONTRACT_ADDRESS_HERE";

// Minimal ABI to interact with BaseAdvancedCounter
const CONTRACT_ABI = [
  "function value() view returns (uint256)",
  "function minValue() view returns (uint256)",
  "function maxValue() view returns (uint256)",
  "function lastUpdated() view returns (uint256)",
  "function paused() view returns (bool)",
  "function increment(uint256 _amount) external",
  "function decrement(uint256 _amount) external"
];

let provider;
let signer;
let contract;

async function connectWallet() {
  if (!window.ethereum) {
    alert("No wallet found. Install MetaMask or a compatible wallet.");
    return;
  }

  await window.ethereum.request({ method: "eth_requestAccounts" });

  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  const account = await signer.getAddress();
  document.getElementById("account").textContent = account;

  await switchToBaseMainnet();

  contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  await updateState();
}

async function switchToBaseMainnet() {
  const baseChainIdHex = "0x2105"; // 8453 in hex

  const currentChainId = await window.ethereum.request({
    method: "eth_chainId",
  });

  if (currentChainId === baseChainIdHex) {
    return;
  }

  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: baseChainIdHex }],
    });
  } catch (error) {
    if (error.code === 4902) {
      // Chain not added in the wallet yet
      await window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [
          {
            chainId: baseChainIdHex,
            chainName: "Base Mainnet",
            nativeCurrency: {
              name: "Ether",
              symbol: "ETH",
              decimals: 18,
            },
            rpcUrls: ["https://mainnet.base.org"],
            blockExplorerUrls: ["https://basescan.org"],
          },
        ],
      });
    } else {
      console.error("Failed to switch chain:", error);
    }
  }
}

function formatTimestamp(ts) {
  const n = Number(ts);
  if (!n) return "-";
  const d = new Date(n * 1000);
  return d.toLocaleString();
}

async function updateState() {
  if (!contract) return;

  const [current, min, max, lastUpdated, paused] = await Promise.all([
    contract.value(),
    contract.minValue(),
    contract.maxValue(),
    contract.lastUpdated(),
    contract.paused(),
  ]);

  document.getElementById("value").textContent = current.toString();
  document.getElementById("min").textContent = min.toString();
  document.getElementById("max").textContent = max.toString();
  document.getElementById("lastUpdated").textContent = formatTimestamp(lastUpdated);

  document.getElementById("status").textContent = paused ? "Paused" : "Active";
}

async function increment() {
  if (!contract) {
    alert("Connect your wallet first.");
    return;
  }

  const input = document.getElementById("amount");
  const amount = input.value || "1";

  try {
    const tx = await contract.increment(ethers.toBigInt(amount));
    await tx.wait();
    await updateState();
  } catch (e) {
    console.error(e);
    alert("Increment failed. Check console for details.");
  }
}

async function decrement() {
  if (!contract) {
    alert("Connect your wallet first.");
    return;
  }

  const input = document.getElementById("amount");
  const amount = input.value || "1";

  try {
    const tx = await contract.decrement(ethers.toBigInt(amount));
    await tx.wait();
    await updateState();
  } catch (e) {
    console.error(e);
    alert("Decrement failed. Check console for details.");
  }
}

document.getElementById("connect").addEventListener("click", connectWallet);
document.getElementById("increment").addEventListener("click", increment);
document.getElementById("decrement").addEventListener("click", decrement);

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BaseAdvancedCounter", function () {
  async function deployFixture() {
    const [owner, other] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("BaseAdvancedCounter");
    const contract = await Factory.deploy(0, 0, 1000);
    return { contract, owner, other };
  }

  it("should deploy with correct initial values", async () => {
    const { contract, owner } = await deployFixture();

    expect(await contract.owner()).to.equal(owner.address);
    expect(await contract.value()).to.equal(0);
    expect(await contract.minValue()).to.equal(0);
    expect(await contract.maxValue()).to.equal(1000);
  });

  it("should increment and decrement within bounds", async () => {
    const { contract } = await deployFixture();

    await contract.increment(10);
    expect(await contract.value()).to.equal(10);

    await contract.decrement(5);
    expect(await contract.value()).to.equal(5);
  });

  it("should revert when going above max", async () => {
    const { contract } = await deployFixture();
    await expect(contract.increment(2000)).to.be.revertedWith("Above max");
  });

  it("should revert when going below min", async () => {
    const { contract } = await deployFixture();
    await expect(contract.decrement(1)).to.be.revertedWith("Underflow");
  });

  it("should allow owner to pause and unpause", async () => {
    const { contract } = await deployFixture();

    await contract.setPaused(true);
    await expect(contract.increment(1)).to.be.revertedWith("Paused");

    await contract.setPaused(false);
    await contract.increment(1);
    expect(await contract.value()).to.equal(1);
  });
});

//QUICK SUMMARY

This TXT is an advanced, ready-to-use Web3 starter for the Base blockchain.

You get: advanced Solidity contract + Hardhat setup + deploy script + basic test + minimal frontend.

Just:

Create a new folder / repo

Copy/paste the files

Run npm install

Run npx hardhat compile && npx hardhat test

Deploy to Base or Base Sepolia

Plug the deployed address into the frontend and open frontend/index.html in a browser with MetaMask.
//