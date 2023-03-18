# Yasp's EVM contracts

Welcome to the YaspFI EVM Contracts repository, which contains multiple vaults based on ERC-4626 for various DeFi protocols. This repository contains smart contracts that allow users to lock up their tokens and auto-compound rewards from different yield DeFi farms.

## Structure

The repository contains the following structure:

 - `src/providers/` This directory contains all of the vault implementations for various DeFi protocols. Each provider has its own subdirectory, which contains a contract that inherits from the Vault contract and implements provider-specific functionality. The providers currently supported include AaveV3, Stargate and Curve.
 - `src/swappers/` contains all swappers that helps Vaults to swap reward tokens back to underlying. Currently we supports Uniswap V3 as an primary swap providers, but is Uniswap V3 is not supported on certain blockchain, we integrate local AMM (like PancakeSwap on BSC or SpookySwap on Fantom)
 - `src/periphery/` This directory contains additional contracts that are used for peripheral functionality of the YaspFI platform.
 - `test/` This directory contains all of the tests for the contracts in the repository. The tests are written in Solidity and use the Foundry. The tests cover all of the functionality of the contracts, including depositing tokens, withdrawing tokens, and auto-compounding rewards.
 - `scripts/` includes all Solidity scripts that was used for deploying contracts via `forge`
## Getting Started
To get started with using these contracts, you can clone the repository and build smart contracts via [Foundry](https://book.getfoundry.sh/)  using this command:
```bash
forge build
```
If you have never used Foundry to develop smart contracts, we highly recommend trying this toolkit because of its coolness and convenience.

## Testing
For each contract, a small set of tests is written to test the concept. Generalized property tests for ERC-4626 contracts have also been integrated, for which many thanks to A16Z for [this repo](https://github.com/a16z/erc4626-tests).
```bash
forge test # Runs all tests
forge test -vvv --match-contract AaveV3VaultStdTest # runs only prop tests for AaveV3 Vault
forge test -vvv --match-contract StargateVaultStdTest # runs only prop tests for Stargate Vault
```

## Deployed addresses

### ETH Goerli

* [Aave V3 Vault Factory](https://goerli.etherscan.io/address/0x9D2AcB1D33eb6936650Dafd6e56c9B2ab0Dd680c)
* [Aave V3 DAI Vault](https://goerli.etherscan.io/address/0x7dDe8BE0fe5E06857F2C416326335787A7C3d30d)
* [Aave V3 EURS Vault](https://goerli.etherscan.io/address/0x0dBEc6Fa48962035B4361a6ED87c47721b6D65ED)
* [Aave V3 USDC Vault](https://goerli.etherscan.io/address/0xD7e182a1c10106Bc85b11d46E7bf7f76475D4FBa)
* [Aave V3 USDT Vault](https://goerli.etherscan.io/address/0x3f42c58162d3106e5Fc040A62a7982752b3DAA1A)
* [Aave V3 AAVE Vault](https://goerli.etherscan.io/address/0xc0FAD04d77643E79121f92DdcA8A60eaa22BDc4B)
* [Aave V3 LINK Vault](https://goerli.etherscan.io/address/0xeA5849d02ba5359174B025abeCcefB7CB4e2A17F)
* [Aave V3 WBTC Vault](https://goerli.etherscan.io/address/0xC796008f3Eb58a30Ef90EBE523b0b077a89aD6fD)
* [Stargate Vault Factory](https://goerli.etherscan.io/address/0x6a86dDcAC0fdc7f5F80BB9566085d4c65A5E3f71)
* [Stargate USDC Vault](https://goerli.etherscan.io/address/0xC796008f3Eb58a30Ef90EBE523b0b077a89aD6fD)

### Optimism

* [Aave V3 Vault Factory](https://optimistic.etherscan.io/0xd847253c30502af5ae84275c52f24b438fdd9fe7)
* [Aave V3 WETH Vault](https://optimistic.etherscan.io/address/0xe0a6da34e1fdd8b0e678010b57bbbb90d9544dfa)
* [Aave V3 DAI Vault](https://optimistic.etherscan.io/address/0x85c6cd5fc71af35e6941d7b53564ac0a68e09f5c)
* [Aave V3 USDT Vault](https://optimistic.etherscan.io/address/0x672b5984274e2a7ad18dfa7c871201d249ca147d)
* [Aave V3 sUSD Vault](https://optimistic.etherscan.io/address/0xef551ae7b9396d943e18ea645a8428825737fc22)
* [Aave V3 USDC Vault](https://optimistic.etherscan.io/address/0x6e6699e4b8ee4bf35e72a41fe366116ff4c5a3df)
* [Aave V3 wBTC Vault](https://optimistic.etherscan.io/address/0x0ea987512a89aaecde837b10d65389a0ab3c8c78)

### Polygon

* [Aave V3 Vault Factory](https://polygonscan.com/address/0x8eae291df7ade0b868d4495673fc595483a9cc24)
* [Aave V3 agEUR Vault](https://polygonscan.com/address/0x9f3047E59c9c541EA6d879e6993691b222796Bc2)
* [Aave V3 DAI Vault](https://polygonscan.com/address/0xfDc514B7118C7DD0737Aa0E18b797A595ADef25a)
* [Aave V3 EURS Vault](https://polygonscan.com/address/0xe51526E446EAa175C55f97E2E01D61bDD2e59D2F)
* [Aave V3 jEUR Vault](https://polygonscan.com/address/0x804bD3Dac4f1d917EC7b20A1A643DE4BB2ba4A05)
* [Aave V3 miMAI Vault](https://polygonscan.com/address/0xEF1e3c9659bA5D10C3284DB7e8e4a57946c88b5d)
* [Aave V3 USDC Vault](https://polygonscan.com/address/0xE7e168DB952b664985145A8Ae12E5Bc4ab101f41)
* [Aave V3 USDT Vault](https://polygonscan.com/address/0x85bAF672385e95d8bbB9841059893f1BA3a34Feb)
* [Aave V3 AAVE Vault](https://polygonscan.com/address/0x2A57f65d0472d7dC422D13A437BC99B5ADD80c6B)
* [Aave V3 BAL Vault](https://polygonscan.com/address/0xC7897f5b3C11e2d9D649dd9770dc7b01bE8129c6)
* [Aave V3 DPI Vault](https://polygonscan.com/address/0xE1B2C649a52fA7F6443486DA7Fd49802520ebB92)
* [Aave V3 LINK Vault](https://polygonscan.com/address/0xd7d10F062F9eb2102e3990513be162B48E2db4b4)
* [Aave V3 stMATIC Vault](https://polygonscan.com/address/0x4336AcDc02A4691b69244C55f5bf183E20a67E54)
* [Aave V3 SUSHI Vault](https://polygonscan.com/address/0x15768Bc22282620D37CCAB7eA71292189688E736)
* [Aave V3 WBTC Vault](https://polygonscan.com/address/0x7C9B0bbb1f29D3fB8e94211693F850c2fafAf275)
* [Aave V3 WETH Vault](https://polygonscan.com/address/0xeFd3f950Ec018ea9FBB49a5034dE9c33439fffbF)
* [Aave V3 WMATIC Vault](https://polygonscan.com/address/0x1d8072BbEb7e547f55c6Ff8f8561374AD6d2330D)

### Arbitrum
* [Aave V3 Vault Factory](https://arbiscan.io/address/0x8eae291df7ade0b868d4495673fc595483a9cc24)
* [Aave V3 DAI Vault](https://arbiscan.io/address/0x76735eCa0d4AdDD4B43398207cfF24d90e0cAe84)
* [Aave V3 EURS Vault](https://arbiscan.io/address/0x60b64E74cCba632aB0A8600F63Ec650E5b0B3A85)
* [Aave V3 USDC Vault](https://arbiscan.io/address/0x67129C42AD3a7381feD1411674D222ea9B670084)
* [Aave V3 USDT Vault](https://arbiscan.io/address/0xe7F87dc14961D80E028Daf1b4C39c4e0910bC4F0)
* [Aave V3 AAVE Vault](https://arbiscan.io/address/0x29D40E576Bd45Aa8c39D9643D4625763A307C5af)
* [Aave V3 LINK Vault](https://arbiscan.io/address/0xD159176DEE5e08a536E91a37Dc51e97f9003b35D)
* [Aave V3 WBTC Vault](https://arbiscan.io/address/0x2DE776423cbc3A4749cF9A9106C937E9a2d9f032)
* [Aave V3 WETH Vault](https://arbiscan.io/address/0x544d88794259Fa823f243831aF2e45F856A7aB3e)

### Fantom

* [Stargate Vault Factory](https://ftmscan.com/address/0x753b5bba84fa79dcc00bee0fcf53b839a782daa4)
* [Stargate USDC Vault](https://ftmscan.com/address/0x364f0dd479942d9a9b4a63c0b2b1700f31c9ae0b)
* [SpookySwap Swapper](https://ftmscan.com/address/0xdbf7876c13e765694a7acf8ac01284c3ef3ac810)
* [Dummy Swapper](https://ftmscan.com/address/0x8eae291df7ade0b868d4495673fc595483a9cc24)
* [Fees Controller](https://ftmscan.com/address/0x9d2acb1d33eb6936650dafd6e56c9b2ab0dd680c)

### Avalanche
* [Aave V3 DAI.e Vault](https://snowtrace.io/address/0x0a8EbE74eA8DC8FdBfb6A2b1F1fCFb572c6406EA)
* [Aave V3 FRAX Vault](https://snowtrace.io/address/0x77129F5f9F5C0538296bDAe777436c0DD27d75F8)
* [Aave V3 MAI Vault](https://snowtrace.io/address/0x8fD6D10f69C294Cf75c88328449Ed382Bc2b15eF)
* [Aave V3 USDC Vault](https://snowtrace.io/address/0x04CEEa256dD75AACc8B7B545f36899EA18377d94)
* [Aave V3 USDT Vault](https://snowtrace.io/address/0xf57A0A2F5d4EF27D3Bc90f05d0231D626cD10674)
* [Aave V3 AAVE.e Vault](https://snowtrace.io/address/0xbA5ecddc122c697466d9BcBdc59aaf1Da1C98C46)
* [Aave V3 BTC.b Vault](https://snowtrace.io/address/0xBa0bF1959Ad8822fd6cCE97BDBA4aF33556F08F8)
* [Aave V3 LINK.e Vault](https://snowtrace.io/address/0x9296d290fb97feB826af6F23688bC8dcB76Ba50F)
* [Aave V3 sAVAX Vault](https://snowtrace.io/address/0x8C9F2bE9A36766417bBff5546Acaadaf15D684D2)
* [Aave V3 WAVAX Vault](https://snowtrace.io/address/0x560EACaA2a7007a2DC26342A7D5da98baEfEdD35)
* [Aave V3 WBTC.e Vault](https://snowtrace.io/address/0x0486fD9eA0Ab8Ae1A0a7a4DC39F0F49517f2dec1)
* [Aave V3 WETH.e Vault](https://snowtrace.io/address/0x5dd836828cB262bE9519c6430dB1bf4cF1Ed850e)

## License
All the contracts in this repository are licensed under the MIT License. You can use these contracts for any commercial or non-commercial purpose, subject to the terms and conditions of the license.
