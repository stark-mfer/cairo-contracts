# stark-mfer

Contracts for the [stark-mfer](https://testnet.playoasis.xyz/collection/0x01e46339056093f0f242ed11aef687ec145a785ddefc125ade1f8d60d0bc64e6) collection. These NFTs are listed via
a [Gradual Dutch Auction](https://www.paradigm.xyz/2022/04/gda) implementation in [Cairo](https://www.cairo-lang.org/docs/).

Claim one via ...

We used [Flipper](https://github.com/Anish-Agnihotri/flipper) to flip the existing [mfer](https://opensea.io/collection/mfers) collection and publish metadata to IPFS at [ipfs://QmRnvgj1sofQBTPXfAZX76ktQecC9Xt4FwPCnsNjLLn5XK/](ipfs://QmRnvgj1sofQBTPXfAZX76ktQecC9Xt4FwPCnsNjLLn5XK/).

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

### How to update ABI

```shell
nile compile
cp artifacts/abi/* ../stark-mfer-frontend/src/abi/
```

### Links

- <https://github.com/Anish-Agnihotri/flipper>
- <https://github.com/OpenZeppelin/nile>
- <https://github.com/OpenZeppelin/cairo-contracts>
- <https://github.com/sambarnes/cairo-dutch>
- <https://github.com/montagao/eth-amsterdam-front>
