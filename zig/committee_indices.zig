const state_transition = @import("state_transition");

const committee_indices = state_transition.committee_indices;
const ByteCount = committee_indices.ByteCount;

var gpa = @import("std").heap.GeneralPurposeAllocator(.{}){};

// this special index 4,294,967,295 is used to mark a not found
pub const NOT_FOUND_INDEX = 0xffffffff;
pub const ERROR_INDEX = 0xffffffff;

export fn computeProposerIndexElectra(
    seed: [*c]u8,
    seed_len: usize,
    active_indices: [*c]u32,
    active_indices_len: usize,
    effective_balance_increments: [*c]u16,
    effective_balance_increments_len: usize,
    max_effective_balance_electra: u64,
    effective_balance_increment: u32,
    rounds: u32,
) u32 {
    const allocator = gpa.allocator();
    // TODO: is it better to define a Result struct with code and value
    const proposer_index = committee_indices.computeProposerIndexElectra(
        allocator,
        seed[0..seed_len],
        active_indices[0..active_indices_len],
        effective_balance_increments[0..effective_balance_increments_len],
        max_effective_balance_electra,
        effective_balance_increment,
        rounds,
    ) catch return ERROR_INDEX;
    return proposer_index;
}

export fn computeProposerIndex(
    seed: [*c]u8,
    seed_len: usize,
    active_indices: [*c]u32,
    active_indices_len: usize,
    effective_balance_increments: [*c]u16,
    effective_balance_increments_len: usize,
    rand_byte_count: ByteCount,
    max_effective_balance: u64,
    effective_balance_increment: u32,
    rounds: u32,
) u32 {
    const allocator = gpa.allocator();
    // TODO: is it better to define a Result struct with code and value
    const proposer_index = committee_indices.computeProposerIndex(
        allocator,
        seed[0..seed_len],
        active_indices[0..active_indices_len],
        effective_balance_increments[0..effective_balance_increments_len],
        rand_byte_count,
        max_effective_balance,
        effective_balance_increment,
        rounds,
    ) catch return ERROR_INDEX;
    return proposer_index;
}

export fn computeSyncCommitteeIndicesElectra(
    seed: [*c]u8,
    seed_len: usize,
    active_indices: [*c]u32,
    active_indices_len: usize,
    effective_balance_increments: [*c]u16,
    effective_balance_increments_len: usize,
    max_effective_balance_electra: u64,
    effective_balance_increment: u32,
    rounds: u32,
    out: [*c]u32,
    out_len: usize,
) c_uint {
    const allocator = gpa.allocator();
    committee_indices.computeSyncCommitteeIndicesElectra(
        allocator,
        seed[0..seed_len],
        active_indices[0..active_indices_len],
        effective_balance_increments[0..effective_balance_increments_len],
        max_effective_balance_electra,
        effective_balance_increment,
        rounds,
        out[0..out_len],
    ) catch return 1;
    return 0;
}

export fn computeSyncCommitteeIndices(
    seed: [*c]u8,
    seed_len: usize,
    active_indices: [*c]u32,
    active_indices_len: usize,
    effective_balance_increments: [*c]u16,
    effective_balance_increments_len: usize,
    rand_byte_count: ByteCount,
    max_effective_balance: u64,
    effective_balance_increment: u32,
    rounds: u32,
    out: [*c]u32,
    out_len: usize,
) c_uint {
    const allocator = gpa.allocator();
    committee_indices.computeSyncCommitteeIndices(
        allocator,
        seed[0..seed_len],
        active_indices[0..active_indices_len],
        effective_balance_increments[0..effective_balance_increments_len],
        rand_byte_count,
        max_effective_balance,
        effective_balance_increment,
        rounds,
        out[0..out_len],
    ) catch return 1;
    return 0;
}
