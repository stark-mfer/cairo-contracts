%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1

#
# ex 1
#

# Storage Vars
@storage_var
func l1_messaging_contract_address_storage() -> (l1_messaging_contract_address : felt):
end

# Event
@event
func sent_message_to_l1(
    l1_contract_address : felt,
    payload_len : felt,
    payload : felt*
    ):
end


@constructor
func constructor{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        l1_messaging_contract_address: felt
    ):
    # Set l1 messaging address
    l1_messaging_contract_address_storage.write(l1_messaging_contract_address)
    return ()
end

# Getter
func get_l1_messaging_contract_address{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (l1_messaging_contract_address : felt):
    let (l1_messaging_contract_address) = l1_messaging_contract_address_storage.read()
    return (l1_messaging_contract_address)
end

# Externals

@external
func create_l1_nft_message{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        l1_user : felt
    ):
    alloc_locals
    # Read l1 messaging address
    let (l1_messaging_contract_address) = l1_messaging_contract_address_storage.read()

    # Constructing the message
    let (message_payload: felt*) = alloc()
    assert message_payload[0] = l1_user

    # Send message to l1
    send_message_to_l1(
        to_address=l1_messaging_contract_address,
        payload_size=1,
        payload=message_payload
    )

    # Emit event
    sent_message_to_l1.emit(
        l1_contract_address=l1_messaging_contract_address,
        payload_len=1,
        payload=message_payload
    )
    return ()
end

#
# ex4
#

@storage_var
func l1_assigned_var_storage() -> (l1_assigned_var_value : felt):
end

#
# getter
#

@view
func l1_assigned_var{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (assigned_var: felt):
    let (assigned_var) = l1_assigned_var_storage.read()
    return (assigned_var)
end

# Consumes message from L1 Evaluator Contract
@l1_handler
func ex4_consumer_l1_message{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
        from_address : felt,
        rand_value : felt
    ):
    l1_assigned_var_storage.write(rand_value)
    return ()
end