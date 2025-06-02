# 🐾 PetBridge: Foster & Adoption dApp

A decentralized application (dApp) built on the **Moonbase Alpha** network to enable transparent and secure pet adoption and fostering. Users can post pets for adoption or foster, apply to care for pets, and receive or send tips to show support. The system ensures fairness by managing refundable application and publication fees, and puts control in the hands of pet publishers for approving applications.

🔗 **Deployed Contract on Moonbase Alpha (Chain ID: 1287)**: [View on Moonscan](https://moonbase.moonscan.io/address/0x7930bc98156049dbdf30ba03a4968263568b5629)

🗺️ **Roadmap**: [View on drive](https://drive.google.com/file/d/1WxjDpqWzGn2o01eGgIqKfFz8Hje2tp8B/view)

---

## 🛠️ Features

### 🐶 User Flow

- Connect your wallet (configured to Moonbase Alpha).
- Publish:
  - A pet for adoption or foster (requires a publish fee).
  - Yourself as a potential foster volunteer (also requires a fee).
- Apply to adopt or foster a pet (requires a refundable application fee).
- Send tips to support:
  - Pet publishers.
  - Foster volunteers.

### 🔐 Publisher Functionality

- Only the **pet publisher** (original uploader) can:
  - Accept or reject incoming adoption/foster requests.
  - Receive fees and tips upon successful matches.

### 🧠 Smart Contract Logic

- Enforces:
  - Publish fee for pet listings and foster volunteers.
  - Refunds for both publish and application fees if the process completes or fails.
  - One request per user per pet.
  - Tipping functionality.
- Stores pet data, application status, and ownership information on-chain.
- Uses custom `Types.sol` definitions for modularity and error handling.

---

## 💻 Technologies Used

### 📦 Smart Contract

- **Solidity**
- **Hardhat** for local development, testing, and deployment
- **Foundry** for testing and fuzzing

### 🖥️ Frontend

- **React**
- **Tailwind CSS** (styling)
- **TypeScript**
- **Ethers.js** (for blockchain interaction)

---

## 🔍 Contract Verification

Since this project uses multiple Solidity files (`PetBridge.sol` imports `Types.sol`), use **Standard JSON Input** for contract verification on [Moonscan](https://moonbase.moonscan.io):

1. In Remix, go to the **Solidity Compiler** tab → Click ⚙️ icon → "Generate Standard JSON Input".
2. Copy the full JSON input.
3. On Moonscan, go to your contract → "Verify and Publish".
4. Select:
   - **Compiler Type**: Multi-part files (via Standard JSON Input)
   - **Compiler Version**: Match the version used in Remix
   - **Optimization**: Yes/No depending on your setting
5. Paste the JSON and submit.

---

## 🧑‍💻 Authors

- **Manuel Maxera**
- **Aixa Irupé Alvarez**

---

## 🪪 License

MIT License
