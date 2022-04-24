"""contract.cairo test file."""
import os
import asyncio
import math
import pytest

from time import sleep
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "ERC721_stark_mfer.cairo")

## Set ERC721 constructor values
NAME = 545218989635115550139762
SYMBOL = 357778736466
OWNER = 1876720107167689448018617017016466019943475564745003415840797961863529937709
START = 1
TOTAL_SUPPLY = 100

# Set price function argument values.
K = 100
ALPHA = 3223093    # 1.5
LAMBDA = 808333361 # 0.01 
MAX_PURCHASE_QUANTITY = 3
BASE_TOKEN_URI_LEN = 3
BASE_TOKEN_URI = [
    184555836509371486644298270517380613565396767415278678887948391494588524912,
    181013377130037559177333561047361651062532691497246656660145932905939821379,
    1278847899718539776412121627913078324061555503
]
TOKEN_URI_SUFFIX = 199354445678

# Utility functions
def felt_to_str(felt):
    length = (felt.bit_length() + 7) // 8
    return felt.to_bytes(length, byteorder="big").decode("utf-8")

def get_purchase_price(
        k: int,
        alpha: float,
        quantity: int,
        lambda_: float,
        time: int,
        total_minted:
        int
    ):
    numerator = k * alpha ** total_minted * (alpha ** quantity - 1)
    denominator = math.exp(lambda_ * time) * (alpha - 1)
    return (numerator / denominator)


### CONTRACT TESTING ###

# Enables modules
@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

# Reusable to save testing time
@pytest.fixture(scope='module')
async def contract_factory():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[
            NAME,
            SYMBOL,
            OWNER,
            START,
            TOTAL_SUPPLY,
            K,
            ALPHA,
            LAMBDA,
            MAX_PURCHASE_QUANTITY,
            BASE_TOKEN_URI_LEN,
            *BASE_TOKEN_URI,
            TOKEN_URI_SUFFIX
        ]
    )
    return contract

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_deployment(contract_factory):
    """Test if the contract was deployed with the correct."""
    contract = contract_factory

    ## Check all constructor argument values succesfully passed in
    name = await contract.name().call()
    assert felt_to_str(name.result.name) == "stark mfer"

    symbol = await contract.symbol().call()
    assert felt_to_str(symbol.result.symbol) == "SMFER"

    supply = await contract.totalSupply().call()
    assert supply.result.total_supply == 100

    supply = await contract.totalSupply().call()
    assert supply.result.total_supply == 100

    tokenURI_ = await contract.tokenURI((1,0)).call()
    tokenURI_felt = tokenURI_.result.token_uri
    tokenURI = "".join(list(map(lambda x: felt_to_str(x), tokenURI_felt)))
    assert tokenURI == "https://gateway.pinata.cloud/ipfs/QmRnvgj1sofQBTPXfAZX76ktQecC9Xt4FwPCnsNjLLn5XK/1.json"


@pytest.mark.asyncio
async def test_DiscreteGDA_purchase_price(contract_factory):
    """Test if the computed purchase price is correct."""
    contract = contract_factory

    # Get auction start time
    start_time_ = await contract.DiscreteGDA_getAuctionStartTime().call()
    start_time = start_time_.result.time
    assert start_time == 0

    # Sleep for 10 seconds
    sleep(10)

    # Compute purchase price
    time_elapsed = start_time + 10

    quantity_ = 3
    purchase_price = get_purchase_price(
        k=K,
        alpha=1.5,
        quantity=quantity_,
        lambda_=0.01,
        time=time_elapsed,
        total_minted=0
    )
    DGDA_purchase_price = await contract.DiscreteGDA_purchase_price(quantity_).call()
    assert DGDA_purchase_price.result.res == purchase_price
