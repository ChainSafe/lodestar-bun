const std = @import("std");
const rocksdb = @import("rocksdb");
const toErrCode = @import("common.zig").toErrCode;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

threadlocal var len: u32 = undefined;
threadlocal var err: i32 = undefined;

//-------------------------------------
// Shared functions
//-------------------------------------

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

//-------------------------------------
// DB functions
//-------------------------------------

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

pub export fn rocksdb_db_destroy(path: [*c]const u8) i32 {
    rocksdb.Database.destroy(std.mem.span(path)) catch |e| {
        err = toErrCode(e);
    };
    return 0;
}

pub export fn rocksdb_db_put(db_ptr: u64, key: [*c]const u8, key_len: u32, value: [*c]const u8, value_len: u32) i32 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    db.put(key[0..key_len], value[0..value_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return 0;
}

// bun-ffi-z: rocksdb_db_get (u64, ptr, u32) ptr
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

//-------------------------------------
// Batch functions
//-------------------------------------

// / bun-ffi-z: rocksdb_writebatch_create_ () ptr
pub export fn rocksdb_writebatch_create_() u64 {
    const batch = rocksdb.WriteBatch.init() catch return 0;
    return @intFromPtr(batch.handle);
}

pub export fn rocksdb_writebatch_destroy_(ptr: u64) void {
    var batch = rocksdb.WriteBatch{ .handle = @ptrFromInt(ptr) };
    batch.destroy();
}

pub export fn rocksdb_writebatch_clear_(ptr: u64) void {
    var batch = rocksdb.WriteBatch{ .handle = @ptrFromInt(ptr) };
    batch.clear();
}

pub export fn rocksdb_writebatch_put_(ptr: u64, key: [*c]const u8, key_len: u32, value: [*c]const u8, value_len: u32) void {
    var batch = rocksdb.WriteBatch{ .handle = @ptrFromInt(ptr) };
    batch.put(key[0..key_len], value[0..value_len]);
}

pub export fn rocksdb_writebatch_delete_(ptr: u64, key: [*c]const u8, key_len: u32) void {
    var batch = rocksdb.WriteBatch{ .handle = @ptrFromInt(ptr) };
    batch.delete(key[0..key_len]);
}

pub export fn rocksdb_db_write(db_ptr: u64, batch_ptr: u64) i32 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    var batch = rocksdb.WriteBatch{ .handle = @ptrFromInt(batch_ptr) };

    db.write(&batch) catch |e| return toErrCode(e);
    return 0;
}

//-------------------------------------
// Iterator functions
//-------------------------------------
// bun-ffi-z: rocksdb_db_create_iterator (u64) ptr
pub export fn rocksdb_db_create_iterator(db_ptr: u64) u64 {
    const db: *rocksdb.Database = @ptrFromInt(db_ptr);
    const iter_ptr = allocator.create(rocksdb.Iterator) catch return 0;
    iter_ptr.* = rocksdb.Iterator.init(db, .{}) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return @intFromPtr(iter_ptr);
}

pub export fn rocksdb_iterator_destroy(iter_ptr: u64) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.destroy();
    allocator.destroy(iter);
}

pub export fn rocksdb_iterator_valid(iter_ptr: u64) bool {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    return iter.valid();
}

pub export fn rocksdb_iterator_seek_to_first(iter_ptr: u64) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.seek_to_first();
}

pub export fn rocksdb_iterator_seek_to_last(iter_ptr: u64) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.seek_to_last();
}

pub export fn rocksdb_iterator_seek(iter_ptr: u64, key: [*c]const u8, key_len: u32) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.seek(key[0..key_len]);
}

pub export fn rocksdb_iterator_next(iter_ptr: u64) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.next();
}

pub export fn rocksdb_iterator_prev(iter_ptr: u64) void {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.prev();
}

// bun-ffi-z: rocksdb_iterator_key (u64) ptr
pub export fn rocksdb_iterator_key(iter_ptr: u64) u64 {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    const key = iter.key();
    len = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: rocksdb_iterator_value (u64) ptr
pub export fn rocksdb_iterator_value(iter_ptr: u64) u64 {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    const value = iter.value();
    len = @intCast(value.len);
    return @intFromPtr(value.ptr);
}

pub export fn rocksdb_iterator_get_error(iter_ptr: u64) i32 {
    const iter: *rocksdb.Iterator = @ptrFromInt(iter_ptr);
    iter.get_error() catch |e| return toErrCode(e);
    return 0;
}
