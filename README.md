# stark-mfer

Contracts for the [stark-mfer](https://testnet.playoasis.xyz/collection/0x01e46339056093f0f242ed11aef687ec145a785ddefc125ade1f8d60d0bc64e6) collection. These NFTs are listed via
a [Gradual Dutch Auction](https://www.paradigm.xyz/2022/04/gda) implementation in [Cairo](https://www.cairo-lang.org/docs/).

Claim one via ...

We used [Flipper](https://github.com/Anish-Agnihotri/flipper) to flip the existing [https://opensea.io/collection/mfers] collection and publish metadat to IPFS (see [nfts/README](./nfts/README.md) for more info).

This project was built for [EthAmsterdam](https://hack.ethglobal.com/ethamsterdam).

## Local Development

### Prerequisites

1. Install Python
1. Install [Poetry](https://python-poetry.org/)
1. Clone this repo

```shell
# Activate a Poetry virtual environment
poetry shell

# Install dependencies
poetry install

# Compile all contracts
nile compile
```

### Links

- <https://github.com/Anish-Agnihotri/flipper>
- <https://github.com/OpenZeppelin/nile>
- <https://github.com/OpenZeppelin/cairo-contracts>
- <https://github.com/sambarnes/cairo-dutch>
- <https://github.com/montagao/eth-amsterdam-front>
