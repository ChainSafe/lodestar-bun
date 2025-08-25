const std = @import("std");
const hashtree = @import("hashtree.zig");
const persistent_merkle_tree = @import("persistent_merkle_tree.zig");

comptime {
    std.testing.refAllDecls(hashtree);
    std.testing.refAllDecls(persistent_merkle_tree);
}
