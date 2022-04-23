# stark-mfer

Contracts for the stark mfer collection. These NFTs are listed via
a [Gradual Dutch Auction](https://www.paradigm.xyz/2022/04/gda) implementation in [Cairo](https://www.cairo-lang.org/docs/).

We used [Flipper](https://github.com/Anish-Agnihotri/flipper) to flip the existing [mfer](https://opensea.io/collection/mfers) collection and publish metadata to IPFS at [ipfs://QmRnvgj1sofQBTPXfAZX76ktQecC9Xt4FwPCnsNjLLn5XK/](ipfs://QmRnvgj1sofQBTPXfAZX76ktQecC9Xt4FwPCnsNjLLn5XK/).

This project was built for [EthAmsterdam](https://hack.ethglobal.com/ethamsterdam).

## Local Development

### Prerequisites

1. Install [Python](https://www.python.org/downloads/)
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

### How to update ABIs in frontend repo

```shell
nile compile
cp artifacts/abis/* ../eth-amsterdam-front/src/abi/
```

### Links

- <https://github.com/Anish-Agnihotri/flipper>
- <https://github.com/OpenZeppelin/nile>
- <https://github.com/OpenZeppelin/cairo-contracts>
- <https://github.com/sambarnes/cairo-dutch>
- <https://github.com/montagao/eth-amsterdam-front>
