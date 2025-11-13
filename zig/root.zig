const std = @import("std");
const hashtree = @import("hashtree.zig");
const persistent_merkle_tree = @import("persistent_merkle_tree.zig");
const bytes = @import("bytes.zig");
const lmdb = @import("lmdb.zig");
const leveldb = @import("leveldb.zig");
const rocksdb = @import("rocksdb.zig");
const snappy = @import("snappy.zig");
const pubkey_map = @import("pubkey_map.zig");
const committee_indices = @import("committee_indices.zig");
const inner_shuffle_list = @import("inner_shuffle_list.zig");
const blst = @import("blst.zig");

comptime {
    std.testing.refAllDecls(hashtree);
    std.testing.refAllDecls(persistent_merkle_tree);
    std.testing.refAllDecls(bytes);
    std.testing.refAllDecls(lmdb);
    std.testing.refAllDecls(leveldb);
    std.testing.refAllDecls(rocksdb);
    std.testing.refAllDecls(snappy);
    std.testing.refAllDecls(pubkey_map);
    std.testing.refAllDecls(inner_shuffle_list);
    std.testing.refAllDecls(committee_indices);
    std.testing.refAllDecls(blst);
}
