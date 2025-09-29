const h = @import("hashtree");
const toErrCode = @import("common.zig").toErrCode;

pub export fn hashtree_hash_(out: [*c]u8, in: [*c]const u8, out_count: usize) i32 {
    h.hash(
        @ptrCast(out[0 .. out_count * 32]),
        @ptrCast(in[0 .. out_count * 64]),
    ) catch |e| return toErrCode(e);
    return 0;
}

pub export fn hashtree_digest64(out: [*c]u8, in: [*c]const u8) i32 {
    h.hash(
        @ptrCast(out[0..32]),
        @ptrCast(in[0..64]),
    ) catch |e| return toErrCode(e);
    return 0;
}

pub export fn hashtree_digest_2_bytes32(out: [*c]u8, a: [*c]const u8, b: [*c]const u8) i32 {
    var in: [64]u8 = undefined;
    @memcpy(in[0..32], a);
    @memcpy(in[32..64], b);
    h.hash(
        @ptrCast(out[0..32]),
        @ptrCast(in[0..64]),
    ) catch |e| return toErrCode(e);
    return 0;
}
