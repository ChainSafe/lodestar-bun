const std = @import("std");

pub export fn u64_to_bytes(value: u64, out: [*c]u8, out_len: u32, little_endian: bool) i32 {
    // This function operates on u64, only 8 bytes can be written
    std.debug.assert(out_len <= 8);

    // Ensure that the value fits in the output buffer
    const value_byte_len = if (value == 0)
        0
    else
        std.math.divCeil(
            std.math.Log2IntCeil(u64),
            std.math.log2_int_ceil(u64, value),
            8,
        ) catch unreachable;
    if (value_byte_len > out_len) return -1;

    var buffer: [8]u8 = undefined;
    std.mem.writeInt(u64, &buffer, value, if (little_endian) .little else .big);
    @memcpy(out, if (little_endian) buffer[0..out_len] else buffer[8 - out_len .. 8]);
    return 0;
}

pub export fn bytes_to_u64(in: [*c]const u8, in_len: u32, little_endian: bool) u64 {
    // This function operates on u64, only 8 bytes can be read
    std.debug.assert(in_len <= 8);

    var buffer: [8]u8 = [_]u8{0} ** 8;
    @memcpy(buffer[0..in_len], if (little_endian) in[0..in_len] else in[8 - in_len .. 8]);
    return std.mem.readInt(u64, &buffer, if (little_endian) .little else .big);
}
