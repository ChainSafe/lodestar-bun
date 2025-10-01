const std = @import("std");
const leveldb = @import("leveldb");
const toErrCode = @import("common.zig").toErrCode;

threadlocal var len: u32 = undefined;
threadlocal var err: i32 = undefined;

// bun-ffi-z: leveldb_get_len_ptr () ptr
pub export fn leveldb_get_len_ptr() u64 {
    return @intFromPtr(&len);
}

// bun-ffi-z: leveldb_get_err_ptr () ptr
pub export fn leveldb_get_err_ptr() u64 {
    return @intFromPtr(&err);
}

pub export fn leveldb_free_(data: u64) void {
    leveldb.free(@ptrFromInt(data));
}

// bun-ffi-z: leveldb_db_open (ptr, bool, bool, bool, u32, i32, u32, i32) ptr
pub export fn leveldb_db_open(
    path: [*c]const u8,
    create_if_missing: bool,
    error_if_exists: bool,
    paranoid_checks: bool,
    write_buffer_size: u32,
    max_open_files: i32,
    block_size: u32,
    block_restart_interval: i32,
) u64 {
    var options = leveldb.Options.create();
    defer options.destroy();

    options.setCreateIfMissing(create_if_missing);
    options.setErrorIfExists(error_if_exists);
    options.setParanoidChecks(paranoid_checks);
    options.setWriteBufferSize(write_buffer_size);
    options.setMaxOpenFiles(max_open_files);
    options.setBlockSize(block_size);
    options.setBlockRestartInterval(block_restart_interval);

    const db = leveldb.DB.open(&options, std.mem.span(path)) catch |e| {
        err = toErrCode(e);
        return 0;
    };
    return @intFromPtr(db.inner);
}

pub export fn leveldb_db_close(db_ptr: u64) void {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };
    db.close();
}

pub export fn leveldb_db_destroy(path: [*c]const u8) i32 {
    var options = leveldb.Options.create();
    defer options.destroy();

    leveldb.destroyDB(&options, std.mem.span(path)) catch |e| return toErrCode(e);
    return 0;
}

pub export fn leveldb_db_put(db_ptr: u64, key: [*c]const u8, key_len: u32, value: [*c]const u8, value_len: u32) i32 {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };

    var options = leveldb.WriteOptions.create();
    defer options.destroy();

    db.put(&options, key[0..key_len], value[0..value_len]) catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: leveldb_db_get (u64, ptr, u32) ptr
pub export fn leveldb_db_get(db_ptr: u64, key: [*c]const u8, key_len: u32) u64 {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };

    var options = leveldb.ReadOptions.create();
    defer options.destroy();

    const value = db.get(&options, key[0..key_len]) catch |e| {
        err = toErrCode(e);
        return 0;
    } orelse {
        err = 0;
        return 0;
    };
    len = @intCast(value.len);
    return @intFromPtr(value.ptr);
}

const napi = @import("napi.zig").napi;
const napiStatusToError = @import("napi.zig").toError;
var gpa: std.heap.DebugAllocator(.{}) = .init;
const allocator = gpa.allocator();

const GetData = struct {
    db_ptr: u64,
    key: []const u8,
    deferred: napi.napi_deferred = undefined,
    value: ?[]const u8 = null,
    err: i32 = 0,
};

fn leveldb_db_get_execute_callback(_: napi.napi_env, data: ?*anyopaque) callconv(.c) void {
    const get_data: *GetData = @alignCast(@ptrCast(data));
    var db = leveldb.DB{ .inner = @ptrFromInt(get_data.db_ptr) };

    var options = leveldb.ReadOptions.create();
    defer options.destroy();

    get_data.value = db.get(&options, get_data.key) catch |e| {
        get_data.err = toErrCode(e);
        return;
    } orelse null;
}

fn leveldb_db_get_complete_callback(env: napi.napi_env, status: napi.napi_status, data: ?*anyopaque) callconv(.c) void {
    const get_data: *GetData = @alignCast(@ptrCast(data));
    defer allocator.destroy(get_data);

    if (status != napi.napi_ok) {
        var error_value: napi.napi_value = undefined;
        _ = napi.napi_create_int32(env, toErrCode(napiStatusToError(status)), &error_value);
        _ = napi.napi_reject_deferred(env, get_data.deferred, error_value);
    } else if (get_data.err != 0) {
        var error_value: napi.napi_value = undefined;
        _ = napi.napi_create_int32(env, get_data.err, &error_value);
        _ = napi.napi_reject_deferred(env, get_data.deferred, error_value);
    } else if (get_data.value) |value| {
        defer leveldb.free(value.ptr);
        var value_buf: napi.napi_value = undefined;
        _ = napi.napi_create_buffer_copy(env, value.len, value.ptr, null, &value_buf);
        _ = napi.napi_resolve_deferred(env, get_data.deferred, value_buf);
    } else {
        var null_value: napi.napi_value = undefined;
        _ = napi.napi_get_null(env, &null_value);
        _ = napi.napi_resolve_deferred(env, get_data.deferred, null_value);
    }
}

// bun-ffi-z: leveldb_db_get_promise (napi_env, u64, ptr, u32) napi_value
pub export fn leveldb_db_get_promise(env: napi.napi_env, db_ptr: u64, key: [*c]const u8, key_len: u32) napi.napi_value {
    const get_data = allocator.create(GetData) catch {
        // Out of memory
        return null;
    };

    get_data.db_ptr = db_ptr;
    get_data.key = key[0..key_len];
    get_data.err = 0;
    get_data.value = null;

    var promise: napi.napi_value = undefined;
    const create_promise_result = napi.napi_create_promise(env, &get_data.deferred, &promise);
    if (create_promise_result != napi.napi_ok) {
        allocator.destroy(get_data);
        return null;
    }
    var async_work: napi.napi_async_work = undefined;
    const create_async_work_result = napi.napi_create_async_work(env, null, null, leveldb_db_get_execute_callback, leveldb_db_get_complete_callback, get_data, &async_work);
    if (create_async_work_result != napi.napi_ok) {
        allocator.destroy(get_data);
        return null;
    }
    const queue_result = napi.napi_queue_async_work(env, async_work);
    if (queue_result != napi.napi_ok) {
        _ = napi.napi_delete_async_work(env, async_work);
        allocator.destroy(get_data);
        return null;
    }
    return promise;
}

pub export fn leveldb_db_delete(db_ptr: u64, key: [*c]const u8, key_len: u32) i32 {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };

    var options = leveldb.WriteOptions.create();
    defer options.destroy();

    db.delete(&options, key[0..key_len]) catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: leveldb_writebatch_create_ () ptr
pub export fn leveldb_writebatch_create_() u64 {
    const batch = leveldb.WriteBatch.create();
    return @intFromPtr(batch.inner);
}

pub export fn leveldb_writebatch_destroy_(ptr: u64) void {
    var batch = leveldb.WriteBatch{ .inner = @ptrFromInt(ptr) };
    batch.destroy();
}

pub export fn leveldb_writebatch_clear_(ptr: u64) void {
    var batch = leveldb.WriteBatch{ .inner = @ptrFromInt(ptr) };
    batch.clear();
}

pub export fn leveldb_writebatch_put_(ptr: u64, key: [*c]const u8, key_len: u32, value: [*c]const u8, value_len: u32) void {
    var batch = leveldb.WriteBatch{ .inner = @ptrFromInt(ptr) };
    batch.put(key[0..key_len], value[0..value_len]);
}

pub export fn leveldb_writebatch_delete_(ptr: u64, key: [*c]const u8, key_len: u32) void {
    var batch = leveldb.WriteBatch{ .inner = @ptrFromInt(ptr) };
    batch.delete(key[0..key_len]);
}

pub export fn leveldb_writebatch_append_(dest_ptr: u64, src_ptr: u64) void {
    var dest = leveldb.WriteBatch{ .inner = @ptrFromInt(dest_ptr) };
    const src = leveldb.WriteBatch{ .inner = @ptrFromInt(src_ptr) };
    dest.append(&src);
}

pub export fn leveldb_db_write(db_ptr: u64, batch_ptr: u64) i32 {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };
    var batch = leveldb.WriteBatch{ .inner = @ptrFromInt(batch_ptr) };

    var options = leveldb.WriteOptions.create();
    defer options.destroy();

    db.write(&options, &batch) catch |e| return toErrCode(e);
    return 0;
}

// bun-ffi-z: leveldb_db_create_iterator (u64) ptr
pub export fn leveldb_db_create_iterator(db_ptr: u64) u64 {
    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };

    var options = leveldb.ReadOptions.create();
    defer options.destroy();

    const iter = db.createIterator(&options);
    return @intFromPtr(iter.inner);
}

pub export fn leveldb_iterator_destroy(iter_ptr: u64) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.destroy();
}

pub export fn leveldb_iterator_valid(iter_ptr: u64) bool {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    return iter.valid();
}

pub export fn leveldb_iterator_seek_to_first(iter_ptr: u64) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.seekToFirst();
}

pub export fn leveldb_iterator_seek_to_last(iter_ptr: u64) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.seekToLast();
}

pub export fn leveldb_iterator_seek(iter_ptr: u64, key: [*c]const u8, key_len: u32) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.seek(key[0..key_len]);
}

pub export fn leveldb_iterator_next(iter_ptr: u64) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.next();
}

pub export fn leveldb_iterator_prev(iter_ptr: u64) void {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.prev();
}

// bun-ffi-z: leveldb_iterator_key (u64) ptr
pub export fn leveldb_iterator_key(iter_ptr: u64) u64 {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    const key = iter.key();
    len = @intCast(key.len);
    return @intFromPtr(key.ptr);
}

// bun-ffi-z: leveldb_iterator_value (u64) ptr
pub export fn leveldb_iterator_value(iter_ptr: u64) u64 {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    const value = iter.value();
    len = @intCast(value.len);
    return @intFromPtr(value.ptr);
}

pub export fn leveldb_iterator_get_error(iter_ptr: u64) i32 {
    var iter = leveldb.Iterator{ .inner = @ptrFromInt(iter_ptr) };
    iter.getError() catch |e| return toErrCode(e);
    return 0;
}
