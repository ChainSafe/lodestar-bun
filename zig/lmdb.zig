const std = @import("std");
const lmdb = @import("lmdb");
const toErrCode = @import("common.zig").toErrCode;

var len_ptr: *u32 = undefined;
var err_ptr: *i32 = undefined;

pub export fn lmdb_set_len_ptr(ptr: *u32) void {
    len_ptr = ptr;
}
pub export fn lmdb_set_err_ptr(ptr: *i32) void {
    err_ptr = ptr;
}

// bun-ffi-z: lmdb_environment_init (ptr, u32, u64) ptr
pub export fn lmdb_environment_init(path: [*c]const u8, max_dbs: u32, map_size: u64) u64 {
    const env = lmdb.Environment.init(path, .{
        .max_dbs = max_dbs,
        .map_size = map_size,
    }) catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    return @intFromPtr(env.ptr);
}

pub export fn lmdb_environment_deinit(env_ptr: u64) void {
    const env = lmdb.Environment{ .ptr = @ptrFromInt(env_ptr) };
    env.deinit();
}

// bun-ffi-z: lmdb_transaction_begin (ptr, bool) ptr
pub export fn lmdb_transaction_begin(env_ptr: u64, read_only: bool) u64 {
    const env = lmdb.Environment{ .ptr = @ptrFromInt(env_ptr) };
    const txn = env.transaction(
        .{ .mode = if (read_only) .ReadOnly else .ReadWrite },
    ) catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    return @intFromPtr(txn.ptr);
}

pub export fn lmdb_transaction_abort(txn_ptr: u64) void {
    const txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) };
    txn.abort();
}

pub export fn lmdb_transaction_commit(txn_ptr: u64) i32 {
    const txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) };
    txn.commit() catch |e| return toErrCode(e);
    return 0;
}

pub export fn lmdb_database_open(txn_ptr: u64, name: [*c]const u8, create: bool, integer_key: bool, reverse_key: bool) u32 {
    const txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) };
    const db = txn.database(name, .{
        .create = create,
        .integer_key = integer_key,
        .reverse_key = reverse_key,
    }) catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    return db.dbi;
}

// bun-ffi-z: lmdb_database_get (ptr, u32, ptr, u32) ptr
pub export fn lmdb_database_get(txn_ptr: u64, db_ptr: u32, key: [*c]const u8, key_len: u32) u64 {
    const db = lmdb.Database{
        .txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) },
        .dbi = db_ptr,
    };
    const val = db.get(key[0..key_len]) catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(val.len);
    return @intFromPtr(val.ptr);
}

pub export fn lmdb_database_set(txn_ptr: u64, db_ptr: u32, key: [*c]const u8, key_len: u32, val: [*c]const u8, val_len: u32) i32 {
    const db = lmdb.Database{
        .txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) },
        .dbi = db_ptr,
    };
    db.set(key[0..key_len], val[0..val_len]) catch |e| return toErrCode(e);
    return 0;
}

pub export fn lmdb_database_delete(txn_ptr: u64, db_ptr: u32, key: [*c]const u8, key_len: u32) i32 {
    const db = lmdb.Database{
        .txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) },
        .dbi = db_ptr,
    };
    db.delete(key[0..key_len]) catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: lmdb_database_cursor (ptr, u32) ptr
pub export fn lmdb_database_cursor(txn_ptr: u64, db_ptr: u32) u64 {
    const db = lmdb.Database{
        .txn = lmdb.Transaction{ .ptr = @ptrFromInt(txn_ptr) },
        .dbi = db_ptr,
    };
    const cursor = db.cursor() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    return @intFromPtr(cursor.ptr);
}

pub export fn lmdb_cursor_deinit(cursor_ptr: u64) void {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    cursor.deinit();
}

// bun-ffi-z: lmdb_cursor_get_current_key (ptr) ptr
pub export fn lmdb_cursor_get_current_key(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const key = cursor.getCurrentKey() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    len_ptr.* = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: lmdb_cursor_get_current_value (ptr) ptr
pub export fn lmdb_cursor_get_current_value(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const value = cursor.getCurrentValue() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    };
    len_ptr.* = @intCast(value.len);
    return @intFromPtr(value.ptr);
}

pub export fn lmdb_cursor_set_current_value(cursor_ptr: u64, val: [*c]const u8, val_len: u32) i32 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    cursor.setCurrentValue(val[0..val_len]) catch |e| return toErrCode(e);
    return 0;
}

pub export fn lmdb_cursor_delete_current_key(cursor_ptr: u64) i32 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    cursor.deleteCurrentKey() catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: lmdb_cursor_go_to_next (ptr) ptr
pub export fn lmdb_cursor_go_to_next(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const key = cursor.goToNext() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: lmdb_cursor_go_to_previous (ptr) ptr
pub export fn lmdb_cursor_go_to_previous(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const key = cursor.goToPrevious() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: lmdb_cursor_go_to_first (ptr) ptr
pub export fn lmdb_cursor_go_to_first(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const key = cursor.goToFirst() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: lmdb_cursor_go_to_last (ptr) ptr
pub export fn lmdb_cursor_go_to_last(cursor_ptr: u64) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const key = cursor.goToLast() catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

pub export fn lmdb_cursor_go_to_key(cursor_ptr: u64, key: [*c]const u8, key_len: u32) i32 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    cursor.goToKey(key[0..key_len]) catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: lmdb_cursor_seek (ptr, ptr, u32) ptr
pub export fn lmdb_cursor_seek(cursor_ptr: u64, key: [*c]const u8, key_len: u32) u64 {
    const cursor = lmdb.Cursor{ .ptr = @ptrFromInt(cursor_ptr) };
    const found_key = cursor.seek(key[0..key_len]) catch |e| {
        err_ptr.* = toErrCode(e);
        return 0;
    } orelse {
        err_ptr.* = 0;
        return 0;
    };
    len_ptr.* = @intCast(found_key.len);
    return @intFromPtr(found_key.ptr);
}
