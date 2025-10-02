const std = @import("std");
const stdx = @import("state_transition:stdx");

const PubkeyIndexMap = stdx.PubkeyIndexMap;
// BLS12-381 pubkey length in bytes
const PUBKEY_INDEX_MAP_KEY_SIZE = 48;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const PubkeyIndexMapU32 = PubkeyIndexMap(u32);

// this special index 4,294,967,295 is used to mark a not found
pub const NOT_FOUND_INDEX = 0xffffffff;
pub const ERROR_INDEX = 0xffffffff;

pub const ErrorCode = struct {
    pub const Success: c_uint = 0;
    pub const InvalidInput: c_uint = 1;
    pub const Error: c_uint = 2;
    pub const TooManyThreadError: c_uint = 2;
    pub const MemoryError: c_uint = 3;
    pub const ThreadError: c_uint = 4;
    pub const InvalidPointerError: c_uint = 5;
    pub const Pending: c_uint = 10;
};

/// C-ABI functions for PubkeyIndexMap
/// create an instance of PubkeyIndexMap
/// this returns a pointer to the instance in the heap which we can use in the following functions
export fn createPubkeyIndexMap() u64 {
    const allocator = gpa.allocator();
    const instance_ptr = PubkeyIndexMapU32.init(allocator) catch return 0;
    return @intFromPtr(instance_ptr);
}

/// destroy an instance of PubkeyIndexMap
export fn destroyPubkeyIndexMap(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    instance_ptr.deinit();
}

/// synchronize this special index to Bun
export fn getNotFoundIndex() c_uint {
    return NOT_FOUND_INDEX;
}

export fn getErrorIndex() c_uint {
    return ERROR_INDEX;
}

/// set a value to the specified PubkeyIndexMap instance
export fn pubkeyIndexMapSet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint, value: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return ErrorCode.InvalidInput;
    }
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    instance_ptr.set(key[0..key_length], value) catch return ErrorCode.Error;
    return ErrorCode.Success;
}

/// get a value from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapGet(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) c_uint {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return NOT_FOUND_INDEX;
    }
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    const value = instance_ptr.get(key[0..key_length]) orelse return NOT_FOUND_INDEX;
    return value;
}

/// clear all values from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapClear(nbr_ptr: u64) void {
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    instance_ptr.clear();
}

/// clone the specified PubkeyIndexMap instance
/// this returns a pointer to the new instance in the heap
export fn pubkeyIndexMapClone(nbr_ptr: u64) u64 {
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    const clone_ptr = instance_ptr.clone() catch return 0;
    return @intFromPtr(clone_ptr);
}

/// check if the specified PubkeyIndexMap instance has the specified key
export fn pubkeyIndexMapHas(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    return instance_ptr.has(key[0..key_length]);
}

/// delete the specified key from the specified PubkeyIndexMap instance
export fn pubkeyIndexMapDelete(nbr_ptr: u64, key: [*c]const u8, key_length: c_uint) bool {
    if (key_length != PUBKEY_INDEX_MAP_KEY_SIZE) {
        return false;
    }
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    return instance_ptr.delete(key[0..key_length]);
}

/// get the size of the specified PubkeyIndexMap instance
export fn pubkeyIndexMapSize(nbr_ptr: u64) c_uint {
    const instance_ptr: *PubkeyIndexMapU32 = @ptrFromInt(nbr_ptr);
    return instance_ptr.size();
}

test "PubkeyIndexMap C-ABI functions" {
    const map = createPubkeyIndexMap();
    defer destroyPubkeyIndexMap(map);

    var key: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    const value = 42;
    _ = pubkeyIndexMapSet(map, &key[0], key.len, value);
    var result = pubkeyIndexMapGet(map, &key[0], key.len);
    try std.testing.expect(result == value);

    // change key
    key[1] = 1;
    result = pubkeyIndexMapGet(map, &key[0], key.len);
    try std.testing.expect(result == 0xffffffff);

    // new instance with same value
    const key2: [PUBKEY_INDEX_MAP_KEY_SIZE]u8 = [_]u8{5} ** PUBKEY_INDEX_MAP_KEY_SIZE;
    result = pubkeyIndexMapGet(map, &key2[0], key2.len);
    try std.testing.expect(result == value);

    // has
    try std.testing.expect(pubkeyIndexMapHas(map, &key2[0], key2.len));

    // size
    try std.testing.expectEqual(1, pubkeyIndexMapSize(map));
    const new_key = ([_]u8{255} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..];
    _ = pubkeyIndexMapSet(map, &new_key[0], new_key.len, 100);
    try std.testing.expectEqual(2, pubkeyIndexMapSize(map));

    // delete
    const missing_key = ([_]u8{254} ** PUBKEY_INDEX_MAP_KEY_SIZE)[0..];
    var del_res = pubkeyIndexMapDelete(map, &missing_key[0], missing_key.len);
    try std.testing.expect(!del_res);
    del_res = pubkeyIndexMapDelete(map, &new_key[0], new_key.len);
    try std.testing.expect(del_res);
    try std.testing.expectEqual(1, pubkeyIndexMapSize(map));

    // clone
    const cloned_map = pubkeyIndexMapClone(map);
    defer destroyPubkeyIndexMap(cloned_map);
    try std.testing.expectEqual(1, pubkeyIndexMapSize(cloned_map));
    result = pubkeyIndexMapGet(cloned_map, &key2[0], key2.len);
    try std.testing.expect(result == value);

    // clear
    pubkeyIndexMapClear(map);
    try std.testing.expectEqual(0, pubkeyIndexMapSize(map));

    // cloned instance is not affected
    try std.testing.expectEqual(1, pubkeyIndexMapSize(cloned_map));
}
