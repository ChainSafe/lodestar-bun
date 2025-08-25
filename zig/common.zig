pub fn toErrCode(err: anyerror) i32 {
    return -@as(i32, @intCast(@intFromError(err)));
}

// bun-ffi-z: err_name (u16) cstring
pub export fn err_name(err_code: u16) [*c]const u8 {
    return @errorName(@errorFromInt(err_code));
}
