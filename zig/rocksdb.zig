const std = @import("std");
const rocksdb = @import("rocksdb");
const toErrCode = @import("common.zig").toErrCode;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

threadlocal var len: u32 = undefined;
threadlocal var err: i32 = undefined;

// bun-ffi-z: rocksdb_get_len_ptr () ptr
pub export fn rocksdb_get_len_ptr() u64 {
    return @intFromPtr(&len);
}

// bun-ffi-z: rocksdb_get_err_ptr () ptr
pub export fn rocksdb_get_err_ptr() u64 {
    return @intFromPtr(&err);
}

pub export fn rocksdb_free_(data: u64) void {
    rocksdb.free(@ptrFromInt(data));
}

// bun-ffi-z: rocksdb_db_open (ptr, bool, bool, bool, u32, i32) ptr
pub export fn rocksdb_db_open(
    path: [*c]const u8,
    create_if_missing: bool,
    error_if_exists: bool,
    paranoid_checks: bool,
    write_buffer_size: u32,
    max_open_files: i32,
) u64 {
    var mode: rocksdb.Options.OpenMode = rocksdb.Options.OpenMode.must_exist;

    if (create_if_missing == true) {
        mode = rocksdb.Options.OpenMode.create_if_missing;
    }

    if (error_if_exists == true) {
        mode = rocksdb.Options.OpenMode.exclusive_create;
    }

    const dbp = allocator.create(rocksdb.Database) catch return 0;

    dbp.* = rocksdb.Database.open(std.mem.span(path), rocksdb.Options{
        .mode = mode,
        .paranoid_checks = paranoid_checks,
        .write_buffer_size = write_buffer_size,
        .max_open_files = max_open_files,
    }) catch |e| {
        err = toErrCode(e);
        return 0;
    };

    return @intFromPtr(dbp);
}

pub export fn rocksdb_db_close(db_ptr: u64) void {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    db.close();
    allocator.destroy(db);
}

pub export fn rocksdb_db_put(db_ptr: u64, key: [*c]const u8, key_len: u32, value: [*c]const u8, value_len: u32) i32 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    db.put(key[0..key_len], value[0..value_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return 0;
}

pub export fn rocksdb_db_get(db_ptr: u64, key: [*c]const u8, key_len: u32) u64 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);

    const value = db.get(key[0..key_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    } orelse {
        err = 0;
        return 0;
    };
    len = @intCast(value.len);
    return @intFromPtr(value.ptr);
}

pub export fn rocksdb_db_delete(db_ptr: u64, key: [*c]const u8, key_len: u32) i32 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    db.delete(key[0..key_len]) catch |e| return toErrCode(e);
    return 0;
}
