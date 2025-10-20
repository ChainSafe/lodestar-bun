const std = @import("std");
const snappy = @import("snappy");
const toErrCode = @import("common.zig").toErrCode;

threadlocal var err: i32 = 0;

// bun-ffi-z: snappy_get_err_ptr () ptr
pub export fn snappy_get_err_ptr() [*c]i32 {
    return &err;
}

// bun-ffi-z: snappy_compress_ (ptr, u32, ptr, u32) ptr
pub export fn snappy_compress_(input: [*c]const u8, input_len: u32, output: [*c]u8, output_len: u32) u64 {
    const length = snappy.compress(input[0..input_len], output[0..output_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return length;
}

// bun-ffi-z: snappy_uncompress_ (ptr, u32, ptr, u32) ptr
pub export fn snappy_uncompress_(input: [*c]const u8, input_len: u32, output: [*c]u8, output_len: u32) u64 {
    const uncompressed = snappy.uncompress(input[0..input_len], output[0..output_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return uncompressed;
}

// bun-ffi-z: snappy_max_compressed_length_ (u64) ptr
pub export fn snappy_max_compressed_length_(source_length: u64) u64 {
    return snappy.maxCompressedLength(source_length);
}

// bun-ffi-z: snappy_uncompressed_length_ (ptr, u32) ptr
pub export fn snappy_uncompressed_length_(compressed: [*c]u8, compressed_len: u32) u64 {
    const length = snappy.uncompressedLength(compressed[0..compressed_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return length;
}

pub export fn snappy_validate_compressed_buffer_(compressed: [*c]u8, compressed_len: u32) i32 {
    snappy.validateCompressedBuffer(compressed[0..compressed_len]) catch |e| {
        return toErrCode(e);
    };
    return 0;
}
