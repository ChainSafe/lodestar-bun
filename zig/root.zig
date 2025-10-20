const std = @import("std");
const hashtree = @import("hashtree.zig");
const persistent_merkle_tree = @import("persistent_merkle_tree.zig");
const bytes = @import("bytes.zig");
const lmdb = @import("lmdb.zig");
const leveldb = @import("leveldb.zig");
const snappy = @import("snappy.zig");

comptime {
    std.testing.refAllDecls(hashtree);
    std.testing.refAllDecls(persistent_merkle_tree);
    std.testing.refAllDecls(bytes);
    std.testing.refAllDecls(lmdb);
    std.testing.refAllDecls(leveldb);
    std.testing.refAllDecls(snappy);
}
