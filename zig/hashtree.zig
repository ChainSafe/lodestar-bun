const h = @import("hashtree");
const toErrCode = @import("common.zig").toErrCode;

pub export fn hashtree_hash_(out: [*c]u8, in: [*c]const u8, out_count: usize) i32 {
    h.hash(
        @ptrCast(out[0 .. out_count * 32]),
        @ptrCast(in[0 .. out_count * 64]),
    ) catch |e| return toErrCode(e);
    return 0;
}
