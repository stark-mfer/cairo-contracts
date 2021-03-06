%lang starknet

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
    get_caller_address,
    get_contract_address
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface
from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_tokenURI,
    ERC721_only_token_owner,
    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn
)

from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.messages import send_message_to_l1

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.ERC721_Metadata_base import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

from contracts.utils.Utils import felt_to_uint256

from contracts.DiscreteGDA import (
    DiscreteGDA_initializer,
    DiscreteGDA_purchase_event,
    DiscreteGDA_currentId,
    DiscreteGDA_initialPrice,
    DiscreteGDA_scaleFactor,
    DiscreteGDA_decayConstant,
    DiscreteGDA_auctionStartTime,
    DiscreteGDA_maxPurchaseQuantity,
    DiscreteGDA_purchase_price,
    DiscreteGDA_price_function_arguments,
    DiscreteGDA_totalTokensMinted,
    DiscreteGDA_setInitialPrice,
    DiscreteGDA_setScaleFactor,
    DiscreteGDA_setDecayConstant,
    DiscreteGDA_purchaseTokens
)


#########################
### STORAGE VARIABLES ###
#########################

# Token URI Storage Variables
# This is a mapping of index to the token URI string
# It has to be split into shorter strings with len < 32
# e.g. 
#        1 -> 'https://gateway.pinata.cloud/ip'
#        2 -> 'fs/QmRnvgj1sofQBTPXfAZX76ktQecC'
#        3 -> '9Xt4FwPCnsNjLLn5XK/
@storage_var
func ERC721_base_token_uri(index : felt) -> (res : felt):
end

# The length of the token URI array
# e.g. [
#        'https://gateway.pinata.cloud/ip',
#        'fs/QmRnvgj1sofQBTPXfAZX76ktQecC',
#        '9Xt4FwPCnsNjLLn5XK/'
#      ]
# len = 3
@storage_var
func ERC721_base_token_uri_len() -> (res : felt):
end

# The suffix of metadate '.json'
@storage_var
func ERC721_base_token_uri_suffix() -> (res : felt):
end

# The total supply of the ERC721 token
@storage_var
func ERC721_total_supply() -> (res : felt):
end


#########################
###### CONSTRUCTOR ######
#########################

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name : felt,
        symbol : felt,
        owner : felt,
        _tokenIdStart : felt,
        _total_supply : felt,
        _initialPrice : felt,
        _scaleFactor : felt,
        _decayConstant : felt,
        _maxPurchaseQuantity : felt,
        base_token_uri_len : felt,
        base_token_uri : felt*,
        token_uri_suffix : felt
    ):
    # Construct Parents
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)

    # Set the total supply
    ERC721_total_supply.write(_total_supply)

    #  Set TokenURI and initial token ID
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix)

    # Initialize GDA parameters
    DiscreteGDA_initializer(
        _tokenIdStart,
        _initialPrice,
        _scaleFactor,
        _decayConstant,
        _maxPurchaseQuantity
    )
    return ()
end


######################################
### Discrete Gradual Dutch Auction ###
######################################

#########################
######## GETTERS ########
#########################

@view
func purchase_price{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt
    ) -> (res : Uint256):
    let (total_cost_uint) = DiscreteGDA_purchase_price(numTokens)
    return (res=total_cost_uint)
end

# View the values of the arguments for the DiscreteGDA price function
@view
func price_function_arguments{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt
    ) -> (res_len : felt, res : felt*):
    let (res_len, res) = DiscreteGDA_price_function_arguments(numTokens)
    return (res_len, res)
end


#########################
######## SETTERS ########
#########################

@external
func setInitialPrice{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }(
        _initialPrice : felt
    ):
    DiscreteGDA_setInitialPrice(_initialPrice)
    return ()
end

@external
func setScaleFactor{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }( 
        _scaleFactor: felt
    ):
    DiscreteGDA_setScaleFactor(_scaleFactor)
    return ()
end

@external
func setDecayConstant{
        pedersen_ptr : HashBuiltin*, 
        syscall_ptr : felt*, 
        range_check_ptr
    }( 
        _decayConstant: felt
    ):
    DiscreteGDA_setDecayConstant(_decayConstant)
    return ()
end


#########################
####### EXTERNALS #######
#########################

@external
func purchaseTokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        numTokens : felt,  
        to : felt,
        value : Uint256
    ):
    DiscreteGDA_purchaseTokens(numTokens, to, value)
    return ()
end


######################################
############## ERC721 ################
######################################

#########################
### STORAGE VARIABLES ###
#########################

# Target L1 ERC721 Contract
@storage_var
func l1_messaging_contract() -> (l1_messaging_contract : felt):
end

#########################
######## EVENTS #########
#########################

@event
func l1_send_initiated(
        tokenId : felt,
        to: felt
):
end

#########################
######## GETTERS ########
#########################

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (total_supply : felt):
    let (total_supply) = ERC721_total_supply.read()
    return (total_supply)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id)
    return (token_uri_len=token_uri_len, token_uri=token_uri)
end


#########################
####### EXTERNALS #######
#########################

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_transferFrom(_from, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        tokenId: Uint256,
        data_len: felt, 
        data: felt*
    ):
    ERC721_safeTransferFrom(_from, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt):
    Ownable_only_owner()
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    Ownable_only_owner()
    ERC721_mint(to, tokenId)
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    ERC721_only_token_owner(tokenId)
    ERC721_burn(tokenId)
    return ()
end

@external
func set_l1_messaging_contract{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(l1 : felt):
    l1_messaging_contract.write(l1)
    return ()
end



# Bridging stuff

@external
func bridge_to_l1{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(recipient: felt, tokenId: Uint256):
    ERC721_only_token_owner(tokenId)
    let (l1_messaging_contr) = l1_messaging_contract.read()
    let (caller_address) = get_caller_address()

    # alloc_locals

    let (message_payload: felt*) = alloc()
    assert message_payload[0] = caller_address
    assert message_payload[1] = recipient
    assert message_payload[2] = tokenId.low

    send_message_to_l1(
        to_address=l1_messaging_contr,
        payload_size=3,
        payload=message_payload
    )

    l1_send_initiated.emit(
        tokenId.low,
        recipient
    )
    return ()
end

@l1_handler
func l1_claimed{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        from_address: felt,
        tokenId : felt
    ):

    let (tokenIdUint) = felt_to_uint256(tokenId)
    ERC721_burn(tokenIdUint)
    return ()
end

@l1_handler
func l1_to_l2{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        from_address: felt,
        to: felt,
        tokenId : felt
    ):

    let (tokenIdUint) = felt_to_uint256(tokenId)
    ERC721_mint(to, (tokenIdUint))
    return ()
end