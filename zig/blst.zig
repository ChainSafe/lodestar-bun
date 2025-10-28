//! C-ABI of the Zig native `blst` bindings.
//!
//! The Zig native types are represented here as their C-ABI equivalent types for bun interoperability.
//!
//! - `SecretKey`: `c.blst_scalar`
//! - `PublicKey`: `c.blst_p1_affine`
//! - `Signature`: `c.blst_p2_affine`
//! - `AggregatePublicKey`: `c.blst_p1`
//! - `AggregateSignature`: `c.blst_p2`
//!
//! We do not define Zig native types for these raw C types in order to not obfuscate the underlying type.

/// Size of the scratch buffer for pairing operations.
pub const SCRATCH_SIZE_PAIRING: usize = blst.Pairing.sizeOf();

/// Scratch buffer used for pairing operations that require temporary storage.
threadlocal var scratch_pairing: [SCRATCH_SIZE_PAIRING]u8 = undefined;

/// Size of the scratch buffer for aggregation operations.
pub const SCRATCH_SIZE_AGG: usize = 1024 * 16;

/// Scratch buffer used for aggregation operations that require temporary storage.
threadlocal var scratch_agg: [SCRATCH_SIZE_AGG]u64 = undefined;

threadlocal var memory_pool: ?*blst.MemoryPoolMinPk = null;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

/// Initializes threadlocal variables prior to performance-sensitive operations.
///
/// Call this before any multi-threaded operations in this binding.
export fn init() c_uint {
    blst.tp.initializeThreadPool(null) catch return c.BLST_BAD_ENCODING;

    const allocator = gpa.allocator();

    var mp = allocator.create(blst.MemoryPoolMinPk) catch unreachable;
    mp.initAlloc(allocator) catch unreachable;
    memory_pool = mp;

    return c.BLST_SUCCESS;
}

/// a Bun application should call this after using any of the exported functions
export fn deinit() void {
    blst.tp.deinitializeThreadPool();
    if (memory_pool) |pool| {
        const allocator = pool.allocator;
        pool.deinit();
        allocator.destroy(pool);
    }
}

////// SecretKey

/// Deserialize `SecretKey` represented as `c.blst_scalar` from bytes.
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyFromBytes(out: *c.blst_scalar, bytes: [*c]const u8, len: c_uint) i32 {
    const deser = SecretKey.deserialize(@ptrCast(bytes[0..len])) catch |e| return toErrCode(e);
    out.* = deser.value;
    return 0;
}

/// Serialize a `SecretKey` represented as `c.blst_scalar` to bytes.
pub export fn secretKeyToBytes(out: [*c]u8, sk_raw: *const c.blst_scalar) void {
    const sk: *const SecretKey = @ptrCast(sk_raw);
    out[0..SecretKey.serialize_size].* = sk.serialize();
}

/// Generate a `SecretKey` represented as `c.blst_scalar` from input key material using HKDF.
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyKeyGen(out: *c.blst_scalar, ikm: [*c]const u8, ikm_len: c_uint) i32 {
    out.* = (SecretKey.keyGen(ikm[0..ikm_len], null) catch |e| return toErrCode(e)).value;
    return 0;
}

/// Generate a `SecretKey` represented as `c.blst_scalar` from input key material using HKDF (version 3).
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyKeyGenV3(out: *c.blst_scalar, ikm: [*c]const u8, ikm_len: c_uint) i32 {
    out.* = (SecretKey.keyGenV3(ikm[0..ikm_len], null) catch |e| return toErrCode(e)).value;
    return 0;
}

/// Generate a `SecretKey` represented as `c.blst_scalar` from input key material using HKDF (version 4.5).
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyKeyGenV45(
    out: *c.blst_scalar,
    ikm: [*c]const u8,
    ikm_len: c_uint,
    salt: [*c]const u8,
    salt_len: c_uint,
) i32 {
    out.* = (SecretKey.keyGenV45(
        ikm[0..ikm_len],
        salt[0..salt_len],
        null,
    ) catch |e| return toErrCode(e)).value;
    return 0;
}

/// Derive a master `SecretKey` represented as `c.blst_scalar` using EIP-2333 key derivation.
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyDeriveMasterEip2333(out: *c.blst_scalar, ikm: [*c]const u8, ikm_len: c_uint) i32 {
    out.* = (SecretKey.deriveMasterEip2333(ikm[0..ikm_len]) catch |e| return toErrCode(e)).value;
    return 0;
}

/// Derive a child `SecretKey` represented as `c.blst_scalar` using EIP-2333 key derivation.
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeyDeriveChildEip2333(out: *c.blst_scalar, sk_raw: *const c.blst_scalar, index: c_uint) i32 {
    const sk: *const SecretKey = @ptrCast(sk_raw);
    out.* = (sk.deriveChildEip2333(index) catch |e| return toErrCode(e)).value;
    return 0;
}

/// Derive a `PublicKey` represented as `c.blst_p1_affine` from a `SecretKey` represented as `c.blst_scalar`.
pub export fn secretKeyToPublicKey(out: *c.blst_p1_affine, sk_raw: *const c.blst_scalar) void {
    const sk: *const SecretKey = @ptrCast(sk_raw);
    out.* = sk.toPublicKey().point;
}

/// Sign a message with `SecretKey` represented as `c.blst_scalar`. and produces a `Signature` represented as `c.blst_p2_affine` in `out`.
///
/// Returns 0 on success, error code on failure.
pub export fn secretKeySign(out: *c.blst_p2_affine, sk_raw: *const c.blst_scalar, msg: [*c]const u8, msg_len: c_uint) i32 {
    const sk: *const SecretKey = @ptrCast(sk_raw);
    out.* = sk.sign(msg[0..msg_len], DST, null).point;
    return 0;
}

////// PublicKey

/// Deserialize a `PublicKey` represented as a `c.blst_p1_affine` in `out` from compressed bytes.
///
/// Returns 0 on success, error code on failure.
pub export fn publicKeyFromBytes(out: *c.blst_p1_affine, bytes: [*c]const u8, len: c_uint) i32 {
    out.* = (PublicKey.uncompress(bytes[0..len]) catch |e| return toErrCode(e)).point;
    return 0;
}

/// Serialize a `PublicKey` represented as a `c.blst_p1_affine` to compressed bytes in `out`.
pub export fn publicKeyToBytes(out: [*c]u8, pk: *const c.blst_p1_affine) void {
    const pk_ptr: *const PublicKey = @ptrCast(pk);
    out[0..PublicKey.COMPRESS_SIZE].* = pk_ptr.compress();
}

/// Validate a `c.blst_p1_affine` point as a valid `PublicKey`.
///
/// Returns 0 on success, error code on failure.
pub export fn publicKeyValidate(a: *const c.blst_p1_affine) i32 {
    const pk: *const PublicKey = @ptrCast(a);
    pk.validate() catch |e| return toErrCode(e);
    return 0;
}
/// Aggregate multiple `Signature`s (as `c.blst_p2_affine`s) and `PublicKey`s (as `c.blst_p1_affine`s) with randomness for security.
///
/// Returns 0 on success, error code on failure.
pub export fn aggregateWithRandomness(
    pk_out: *c.blst_p1_affine,
    sig_out: *c.blst_p2_affine,
    len: c_uint,
    pks: [*c]*const *c.blst_p1_affine,
    sigs: [*c]*const c.blst_p2_affine,
    pks_validate: bool,
    sigs_groupcheck: bool,
) i32 {
    var rands: [32 * MAX_AGGREGATE_PER_JOB]u8 = [_]u8{0} ** (32 * MAX_AGGREGATE_PER_JOB);
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    std.Random.bytes(rand, &rands);

    const agg_sig = AggregateSignature.aggregateWithRandomness(
        sigs[0..len],
        &rands,
        sigs_groupcheck,
        scratch_agg[0..],
    ) catch |e| return toErrCode(e);
    sig_out.* = agg_sig.toSignature().point;

    const agg_pk = AggregatePublicKey.aggregateWithRandomness(
        pks[0..len],
        &rands,
        pks_validate,
        scratch_agg[0..],
    ) catch |e| return toErrCode(e);
    pk_out.* = agg_pk.toPublicKey().point;

    return 0;
}

/// Aggregate multiple `PublicKey`s (as `c.blst_p1_affine`s) with randomness for security.
///
/// Returns 0 on success, error code on failure.
pub export fn publicKeyAggregateWithRandomness(
    out: *c.blst_p1_affine,
    pks: [*c]*const c.blst_p1_affine,
    len: c_uint,
    pks_validate: bool,
) i32 {
    var rands: [32 * MAX_AGGREGATE_PER_JOB]u8 = [_]u8{0} ** (32 * MAX_AGGREGATE_PER_JOB);
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    std.Random.bytes(rand, &rands);

    const agg_pk = AggregatePublicKey.aggregateWithRandomness(
        pks[0..len],
        &rands,
        pks_validate,
        scratch_agg[0..],
    ) catch |e| return toErrCode(e);

    out.* = agg_pk.toPublicKey().point;

    return 0;
}

/// Aggregate multiple `PublicKey`s (as `c.blst_p1_affine`s).
///
/// Returns 0 on success, error code on failure.
pub export fn publicKeyAggregate(out: *c.blst_p1_affine, pks: [*c]const c.blst_p1_affine, len: c_uint, pks_validate: bool) i32 {
    const agg_pk = AggregatePublicKey.aggregate(@ptrCast(pks[0..len]), pks_validate) catch |e| return toErrCode(e);
    out.* = agg_pk.toPublicKey().point;

    return 0;
}

////// Signature

/// Deserialize a `Signature` as `c.blst_p2_affine` in `out` from compressed bytes.
///
/// Returns 0 on success, error code on failure.
pub export fn signatureFromBytes(out: *c.blst_p2_affine, bytes: [*c]const u8, bytes_len: c_uint) i32 {
    out.* = (Signature.uncompress(bytes[0..bytes_len]) catch |e| return toErrCode(e)).point;
    return 0;
}

/// Serialize a `Signature` as `c.blst_p2_affine` to compressed bytes in `out`.
pub export fn signatureToBytes(out: [*c]u8, sig: *const c.blst_p2_affine) void {
    const sig_ptr: *const Signature = @ptrCast(sig);
    out[0..Signature.COMPRESS_SIZE].* = sig_ptr.compress();
}

/// Validate a `c.blst_p2_affine` as a valid `Signature`.
///
/// Returns 0 on success, error code on failure.
pub export fn signatureValidate(sig: *const c.blst_p2_affine, sig_infcheck: bool) i32 {
    const sig_ptr: *const Signature = @ptrCast(sig);
    sig_ptr.validate(sig_infcheck) catch |e| return toErrCode(e);
    return 0;
}

/// Verify a `Signature` (as `c.blst_p2_affine`) against a `PublicKey` (`c.blst_p1_affine`) and message `msg`.
///
/// Returns 0 on success, error code on failure.
pub export fn signatureVerify(
    sig: *const c.blst_p2_affine,
    sig_groupcheck: bool,
    msg: [*c]const u8,
    msg_len: c_uint,
    pk: *const c.blst_p1_affine,
    pk_validate: bool,
) i32 {
    const sig_ptr: *const Signature = @ptrCast(sig);
    sig_ptr.verify(
        sig_groupcheck,
        msg[0..msg_len],
        DST,
        null,
        @ptrCast(pk),
        pk_validate,
    ) catch |e| return toErrCode(e);
    return 0;
}

/// Verify an aggregate signature `c.blst_p2_affine` against multiple messages and `c.blst_p1_affine`s.
///
/// Returns 0 if verification succeeds, 1 if verification fails, error code on error.
pub export fn signatureAggregateVerify(
    sig: *const c.blst_p2_affine,
    sig_groupcheck: bool,
    msgs: [*c]const *[32]u8,
    pks: [*c]const *const c.blst_p1_affine,
    len: c_uint,
    pks_validate: bool,
) i32 {
    const sig_ptr: *const Signature = @ptrCast(sig);

    const res = sig_ptr.aggregateVerifyTwo(
        sig_groupcheck,
        msgs[0..len],
        32,
        DST,
        @ptrCast(pks[0..len]),
        pks_validate,
        if (memory_pool) |mp| mp else @panic("Memory pool is not initialized"),
    );
    return @intCast(res);
}

/// Faster verify an aggregated signature `Signature` (as `c.blst_p2_affine`) against multiple messages and `PublicKey`s (as `c.blst_p1_affine`s).
///
/// Returns 0 if verification succeeds, 1 if verification fails, error code on error.
pub export fn signatureFastAggregateVerify(
    sig: *const c.blst_p2_affine,
    sig_groupcheck: bool,
    msg: *[32]u8,
    pks: [*c]const c.blst_p1_affine,
    pks_len: c_uint,
) i32 {
    const sig_ptr: *const Signature = @ptrCast(sig);
    const res = sig_ptr.fastAggregateVerify(
        sig_groupcheck,
        &scratch_pairing,
        msg,
        DST,
        @ptrCast(pks[0..pks_len]),
    ) catch |e| return toErrCode(e);
    return @intFromBool(!res);
}

/// Verify multiple aggregate signatures efficiently.
///
/// Returns 0 if verification succeeds, 1 if verification fails, error code on error.
pub export fn signatureVerifyMultipleAggregateSignatures(
    n_elems: c_uint,
    msgs: [*c]const [32]u8,
    pks: [*c]const *c.blst_p1_affine,
    pks_validate: bool,
    sigs: [*c]const *c.blst_p2_affine,
    sig_groupcheck: bool,
) i32 {
    var rands: [32 * MAX_AGGREGATE_PER_JOB][32]u8 = undefined;
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();

    for (0..32 * MAX_AGGREGATE_PER_JOB) |i| {
        std.Random.bytes(rand, &rands[i]);
    }

    const res = blst.verifyMultipleAggregateSignatures(
        &scratch_pairing,
        n_elems,
        msgs[0..n_elems],
        DST,
        @ptrCast(pks[0..n_elems]),
        pks_validate,
        @ptrCast(sigs[0..n_elems]),
        sig_groupcheck,
        &rands,
    ) catch |e| return toErrCode(e);

    return @intFromBool(!res);
}

/// Aggregates a slice of `Signature`s (as `c.blst_p2_affine`) with randomness into a single `Signature` (represented as `c.blst_p2_affine`).
///
/// Returns 0 on success, error code on failure.
pub export fn signatureAggregateWithRandomness(
    out: *c.blst_p2_affine,
    sigs: [*c]*const c.blst_p2_affine,
    len: c_uint,
    sigs_groupcheck: bool,
) i32 {
    var rands: [32 * MAX_AGGREGATE_PER_JOB]u8 = [_]u8{0} ** (32 * MAX_AGGREGATE_PER_JOB);
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    std.Random.bytes(rand, &rands);

    const agg_sig = AggregateSignature.aggregateWithRandomness(
        sigs[0..len],
        &rands,
        sigs_groupcheck,
        scratch_agg[0..],
    ) catch |e| return toErrCode(e);

    out.* = agg_sig.toSignature().point;

    return 0;
}

/// Aggregates a slice of `Signature`s (as `c.blst_p2_affine`) into a single `Signature` (represented as `c.blst_p2_affine`).
///
/// Returns 0 on success, error code on failure.
pub export fn signatureAggregate(
    out: *c.blst_p2_affine,
    sigs: [*c]const c.blst_p2_affine,
    len: c_uint,
    sigs_groupcheck: bool,
) i32 {
    const agg_sig = AggregateSignature.aggregate(
        @ptrCast(sigs[0..len]),
        sigs_groupcheck,
    ) catch |e| return toErrCode(e);

    out.* = agg_sig.toSignature().point;

    return 0;
}

const std = @import("std");
const blst = @import("blst");
const Signature = blst.Signature;
const PublicKey = blst.PublicKey;
const SecretKey = blst.SecretKey;
const AggregateSignature = blst.AggregateSignature;
const AggregatePublicKey = blst.AggregatePublicKey;
const MP = blst.MemoryPoolMinPk;
const DST = blst.DST;
const MAX_AGGREGATE_PER_JOB = blst.MAX_AGGREGATE_PER_JOB;
const toErrCode = @import("common.zig").toErrCode;

const c = blst.c;
