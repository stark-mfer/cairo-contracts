%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt


#
# Converts a felt into a Uint256. With a low, and high
# - eg. x : felt = 1 is equivalent to x : Uint256(1, 0)
#
func felt_to_uint256{range_check_ptr}(x) -> (uint_x : Uint256):
    let split = split_felt(x)
    return (Uint256(low=split.low, high=split.high))
end