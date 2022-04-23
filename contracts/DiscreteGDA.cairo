%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from openzeppelin.utils.constants import TRUE
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le
)

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_mul,
    uint256_sub,
)

from openzeppelin.access.ownable import Ownable_only_owner

from openzeppelin.token.erc721.library import ERC721_mint

from contracts.Math64x61 import ( 
    Math64x61_fromFelt, 
    Math64x61_toFelt,
    Math64x61_sub,
    Math64x61_mul,
    Math64x61_div,
    Math64x61_pow,
    Math64x61_exp,
    Math64x61_toUint256,
    Math64x61_ONE
)

from contracts.utils.Utils import felt_to_uint256


#########################
###### INITIALIZER ######
#########################

func DiscreteGDA_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _tokenIdStart : felt,
        _initialPrice : felt,
        _scaleFactor : felt,
        _decayConstant : felt,
        _maxPurchaseQuantity : felt
    ):
    DiscreteGDA_currentId.write(_tokenIdStart)
    DiscreteGDA_initialPrice.write(_initialPrice)
    DiscreteGDA_scaleFactor.write(_scaleFactor)
    DiscreteGDA_decayConstant.write(_decayConstant)
    DiscreteGDA_maxPurchaseQuantity.write(_maxPurchaseQuantity)

    let (block_timestamp) = get_block_timestamp()
    let (fixedTimestamp) = Math64x61_fromFelt(block_timestamp)
    DiscreteGDA_auctionStartTime.write(fixedTimestamp)
    return ()
end


#########################
### STORAGE VARIABLES ###
#########################

# Current NFT ID
@storage_var
func DiscreteGDA_currentId() -> (res : felt):
end

# parameter that controls initial price
@storage_var
func DiscreteGDA_initialPrice() -> (res : felt):
end

# parameter that controls how much the starting price of each successive auction increases by
@storage_var
func DiscreteGDA_scaleFactor() -> (res : felt):
end

# parameter that controls price decay
@storage_var
func DiscreteGDA_decayConstant() -> (res : felt):
end

# start time for all auctions
@storage_var
func DiscreteGDA_auctionStartTime() -> (res : felt):
end

# maximum tokens that can be bought per purchase
@storage_var
func DiscreteGDA_maxPurchaseQuantity() -> (res : felt):
end


#########################
######### EVENTS ########
#########################

@event
func DiscreteGDA_purchase_event(
        numTokens : felt,
        to : felt,
        value : Uint256
):
end


#########################
######## GETTERS ########
#########################

# https://github.com/sambarnes/cairo-dutch/pull/1
# View the current purchase price for a given number of tokens
@view
func DiscreteGDA_purchase_price{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt
    ) -> (res : Uint256):
    alloc_locals

    let (local current_id) = DiscreteGDA_currentId.read()
    let (local auction_start_time) = DiscreteGDA_auctionStartTime.read()
    let (local initial_price) = DiscreteGDA_initialPrice.read()
    let (local decay_constant) = DiscreteGDA_decayConstant.read()

    let (quantity) = Math64x61_fromFelt(numTokens)
    let (num_sold) = Math64x61_fromFelt(current_id)

    let (block_timestamp) = get_block_timestamp()
    let (fixedTimestamp) = Math64x61_fromFelt(block_timestamp)
    let (time_since_start) = Math64x61_sub(fixedTimestamp, auction_start_time)

    let (scale_factor) = DiscreteGDA_scaleFactor.read()

    let (local pow_num) = Math64x61_pow(scale_factor, num_sold)
    let (local pow_num2) = Math64x61_pow(scale_factor, quantity)
    let (local mul_num1) = Math64x61_mul(decay_constant, time_since_start)

    let (num1) = Math64x61_mul(initial_price, pow_num)
    let (num2) = Math64x61_sub(pow_num2, Math64x61_ONE)

    let (den1) = Math64x61_exp(mul_num1) 
    let (den2) = Math64x61_sub(scale_factor, Math64x61_ONE)

    let (local mul_num2) = Math64x61_mul(num1, num2)
    let (local mul_num3) = Math64x61_mul(den1, den2)

    let (local total_cost) = Math64x61_div(mul_num2, mul_num3)
    let (total_cost_uint) = Math64x61_toUint256(total_cost)

    return (res=total_cost_uint)
end

# View the values of the arguments for the DiscreteGDA price function
@view
func DiscreteGDA_price_function_arguments{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt
    ) -> (res_len : felt, res : felt*):
    alloc_locals

    let (local res : felt*) = alloc()

    let (local current_id) = DiscreteGDA_currentId.read()
    let (local auction_start_time) = DiscreteGDA_auctionStartTime.read()
    let (local initial_price) = DiscreteGDA_initialPrice.read()
    let (local decay_constant) = DiscreteGDA_decayConstant.read()

    let (quantity) = Math64x61_fromFelt(numTokens)
    let (num_sold) = Math64x61_fromFelt(current_id)

    let (block_timestamp) = get_block_timestamp()
    let (fixedTimestamp) = Math64x61_fromFelt(block_timestamp)
    let (time_since_start) = Math64x61_sub(fixedTimestamp, auction_start_time)

    let (scale_factor) = DiscreteGDA_scaleFactor.read()

    let (local pow_num) = Math64x61_pow(scale_factor, num_sold)
    let (local pow_num2) = Math64x61_pow(scale_factor, quantity)
    let (local mul_num1) = Math64x61_mul(decay_constant, time_since_start)

    let (num1) = Math64x61_mul(initial_price, pow_num)
    let (num2) = Math64x61_sub(pow_num2, Math64x61_ONE)

    let (den1) = Math64x61_exp(mul_num1) 
    let (den2) = Math64x61_sub(scale_factor, Math64x61_ONE)

    assert [res]     = initial_price    # k
    assert [res + 1] = scale_factor     # alpha
    assert [res + 2] = decay_constant   # lambda
    assert [res + 3] = quantity         # q
    assert [res + 4] = num_sold         # m
    assert [res + 5] = time_since_start # T

    return (res_len=6, res=res)
end

# Get current total number of tokens minted
@view
func DiscreteGDA_totalTokensMinted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (total_minted : felt):
    let (total_minted) = DiscreteGDA_currentId.read()
    return (total_minted)
end


#########################
######## SETTERS ########
#########################

@external
func DiscreteGDA_setInitialPrice{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }(
        _initialPrice : felt
    ):
    Ownable_only_owner()
    DiscreteGDA_initialPrice.write(_initialPrice)
    return ()
end

@external
func DiscreteGDA_setScaleFactor{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }( 
        _scaleFactor : felt
    ):
    Ownable_only_owner()
    DiscreteGDA_scaleFactor.write(_scaleFactor)
    return ()
end

@external
func DiscreteGDA_setDecayConstant{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }( 
        _decayConstant : felt
    ):
    Ownable_only_owner()
    DiscreteGDA_decayConstant.write(_decayConstant)
    return ()
end


#########################
####### EXTERNALS #######
#########################

@external
func DiscreteGDA_purchaseTokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt,  
        to : felt,
        value : Uint256
    ):
    alloc_locals

    let (max_purchase) = DiscreteGDA_maxPurchaseQuantity.read()
    with_attr error_message("Number of tokens is more than the max defined."):
        assert_le(numTokens, max_purchase)
    end

    let (price) = DiscreteGDA_purchase_price(numTokens)
    let (is_valid_bid) = uint256_le(price, value)
    with_attr error_message("Insufficient payment."):
        assert is_valid_bid = TRUE
    end

    # Mint all tokens
    _DiscreteGDA_mint_batch(to, numTokens)

    # Emit purchase event
    DiscreteGDA_purchase_event.emit(numTokens=numTokens, to=to, value=value)

    return ()
end


#########################
####### INTERNALS #######
#########################

func _DiscreteGDA_mint_batch{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, amount : felt) -> ():
    alloc_locals
    assert_not_zero(to)

    if amount == 0:
        return ()
    end

    let (local current_id) = DiscreteGDA_currentId.read()
    let (current_id_uint : Uint256) = felt_to_uint256(current_id)
    ERC721_mint(to, current_id_uint)

    DiscreteGDA_currentId.write(current_id + 1)

    return _DiscreteGDA_mint_batch(
        to=to,
        amount=(amount - 1))
end
