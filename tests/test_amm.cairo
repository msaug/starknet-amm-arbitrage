%lang starknet

from src.IAmm import IAmm
from lib.utils import parse_units
from starkware.cairo.common.math import assert_in_range
from starkware.cairo.common.bool import TRUE, FALSE
# Setup a test with an active reserve for test_token

const TOKEN_A = 42
const TOKEN_B = 1337

@view
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    %{ context.amm1 = deploy_contract("./src/mock_amm.cairo").contract_address %}
    return ()
end

func get_contract_addresses() -> (amm1 : felt):
    tempvar amm1
    %{ ids.amm1 = context.amm1 %}
    return (amm1)
end

@view
func test_reserves{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local amm1) = get_contract_addresses()
    let (a1) = parse_units(5000, 18)
    let (b1) = parse_units(10, 18)

    IAmm.set_reserves(amm1, TOKEN_A, TOKEN_B, a1, b1)

    let (reserve1, reserve2, inversed) = IAmm.get_reserves(amm1, TOKEN_A, TOKEN_B)
    assert reserve1 = a1
    assert reserve2 = b1
    assert inversed = FALSE

    let (reserve1, reserve2, inversed) = IAmm.get_reserves(amm1, TOKEN_B, TOKEN_A)
    assert reserve1 = a1
    assert reserve2 = b1
    assert inversed = TRUE
    return ()
end

@view
func test_balance{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local amm1) = get_contract_addresses()
    let (balance_a_1) = parse_units(10, 18)  # 10 / 5000 total
    let (balance_b_1) = parse_units(10, 16)  # 0.01 / 10 total

    IAmm.set_user_balance(amm1, TOKEN_A, balance_a_1)
    IAmm.set_user_balance(amm1, TOKEN_B, balance_b_1)

    let (stored_a) = IAmm.get_user_balance(amm1, TOKEN_A)
    let (stored_b) = IAmm.get_user_balance(amm1, TOKEN_B)
    assert stored_a = balance_a_1
    assert stored_b = balance_b_1
    return ()
end

@view
func test_swap{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local amm1) = get_contract_addresses()

    # Set reserves
    let (a1) = parse_units(5000, 18)
    let (b1) = parse_units(10, 18)
    IAmm.set_reserves(amm1, TOKEN_A, TOKEN_B, a1, b1)

    # Set balances
    let (balance_a_1) = parse_units(10, 18)  # 10 / 5000 total
    let (balance_b_1) = parse_units(10, 16)  # 0.01 / 10 total
    IAmm.set_user_balance(amm1, TOKEN_A, balance_a_1)
    IAmm.set_user_balance(amm1, TOKEN_B, balance_b_1)

    # Swap tokens
    let (swap_amount) = parse_units(5, 18)  # swap 5 token A
    IAmm.swap(amm1, TOKEN_A, TOKEN_B, swap_amount)
    let theoritical_received_amt = 9990009990009990  # this is 9,99000999... e15, since we're operating on 18 decimals the precision stops here
    # Check balances
    let (balance_a) = IAmm.get_user_balance(amm1, TOKEN_A)
    let (balance_b) = IAmm.get_user_balance(amm1, TOKEN_B)
    assert balance_a = balance_a_1 - swap_amount
    assert balance_b = balance_b_1 + theoritical_received_amt

    # Check reserves
    let (reserve1, reserve2, inversed) = IAmm.get_reserves(amm1, TOKEN_A, TOKEN_B)
    assert reserve1 = a1 + swap_amount
    assert reserve2 = b1 - theoritical_received_amt
    return ()
end
