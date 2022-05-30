%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import (unsigned_div_rem, split_felt)


# Seed for pseudorandom
@storage_var
func entropy_seed(
    ) -> (
        value : felt
    ):
end

namespace ns_prng:

    # Gets hard-to-predict values as pseudorandom number
    # Referencing the great Perama (@eth_worm) at https://github.com/dopedao/RYO/blob/main/contracts/GameEngineV1.cairo
    func init_seed {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        seed : felt) -> ():

        entropy_seed.write (seed)

        return ()
    end

    func get_prn {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            entropy : felt
        ) -> (
            num : felt
        ):
        # Seed is fed to linear congruential generator.
        # seed = (multiplier * seed + increment) % modulus.
        # Params from GCC. (https://en.wikipedia.org/wiki/Linear_congruential_generator).
        let (old_seed) = entropy_seed.read ()
        # Snip in half to a manageable size for unsigned_div_rem.
        let (_, low) = split_felt (old_seed)
        let (_, new_seed_) = unsigned_div_rem (1103515245 * low + 1, 2**31)

        # Number has form: 10**9 (xxxxxxxxxx).
        # Should be okay to write multiple times to same variable
        # without increasing storage costs of this transaction.
        let (new_seed) = hash2 {hash_ptr = pedersen_ptr} (new_seed_, entropy)
        entropy_seed.write (new_seed)

        return (new_seed)
    end

    func get_prn_mod {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            mod : felt,
            entropy : felt
        ) -> (
            num : felt
        ):

        let (prn) = get_prn (entropy)
        let (_, prn_low) = split_felt (prn) ## split in half before modulo
        let (_, num) = unsigned_div_rem (prn_low, mod)

        return (num)
    end

end # end namespace
