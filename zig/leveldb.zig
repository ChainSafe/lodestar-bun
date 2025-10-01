const std = @import("std");
const leveldb = @import("leveldb");
const toErrCode = @import("common.zig").toErrCode;

threadlocal var len: u32 = undefined;
threadlocal var err: i32 = undefined;

const allocator = std.heap.c_allocator;

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

// Single value representation when returning many values
pub const ResultRef = extern struct {
    // Pointer to the value allocated with malloc within LevelDB
    ptr: u64,
    // Length of the item returned from the leveldb
    len: u32,
    // Define if the result is empty or does not exists
    // To cross platform C ABI compatibility we are using u8 instead of bool
    found: u8,
};

pub export fn leveldb_get_result_ref_byte_size() u32 {
    return @intCast(@sizeOf(ResultRef));
}

pub export fn leveldb_db_result_ref_free(result_ptr: u64, count: u32, clean_values: bool) void {
    if (result_ptr == 0) return;
    var results: [*]ResultRef = @ptrFromInt(result_ptr);

    if (clean_values) {
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (results[i].found == 1 and results[i].ptr != 0) {
                leveldb.free(@ptrFromInt(results[i].ptr));
            }
        }
    }

    allocator.free(results[0..count]);
}

// bun-ffi-z: leveldb_db_get_many (u64, ptr, ptr, u32) ptr
pub export fn leveldb_db_get_many(db_ptr: u64, keys_ptrs: [*c]const [*c]const u8, key_lens: [*c]const u32, count: u32) u64 {
    // Reset the local thread references
    err = 0;
    len = 0;

    if (keys_ptrs == null or key_lens == null or count == 0) {
        return 0;
    }

    var db = leveldb.DB{ .inner = @ptrFromInt(db_ptr) };
    var options = leveldb.ReadOptions.create();
    defer options.destroy();

    // Initialize the result array for th length of the requested keys
    var results = allocator.alloc(ResultRef, count) catch {
        err = toErrCode(error.OutOfMemory);
        return 0;
    };
    // Initialize all results to zeros meant not-found
    @memset(results, std.mem.zeroes(ResultRef));

    // If function encounter an error free up all memory
    errdefer leveldb_db_result_ref_free(@intFromPtr(results.ptr), count, true);

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const kptr: [*]const u8 = keys_ptrs[i];
        const klen: u32 = key_lens[i];

        const maybe_val = db.get(&options, kptr[0..klen]) catch |e| {
            err = toErrCode(e);
            return 0;
        };

        if (maybe_val) |val| {
            results[i] = .{
                .ptr = @intFromPtr(val.ptr),
                .len = @intCast(val.len),
                .found = 1,
            };
        }
    }

    len = count;
    return @intFromPtr(results.ptr);
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
