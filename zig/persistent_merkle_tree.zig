const std = @import("std");
const pmt = @import("ssz:persistent_merkle_tree");
const toErrCode = @import("common.zig").toErrCode;

var allocator = std.heap.GeneralPurposeAllocator(.{}){};
var pool: pmt.Node.Pool = undefined;

// Pool

pub export fn persistent_merkle_tree_pool_init(pool_size: u32) i32 {
    pool = pmt.Node.Pool.init(allocator.allocator(), pool_size) catch |e| return toErrCode(e);
    return 0;
}

pub export fn persistent_merkle_tree_pool_deinit() void {
    pool.deinit();
}

pub export fn persistent_merkle_tree_pool_create_leaf(hash: [*c]u8, should_ref: bool) i32 {
    const id = pmt.Node.Pool.createLeaf(
        &pool,
        hash[0..32],
        should_ref,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(id));
}

pub export fn persistent_merkle_tree_pool_create_branch(left_id: u32, right_id: u32, should_ref: bool) i32 {
    const id = pmt.Node.Pool.createBranch(
        &pool,
        @enumFromInt(left_id),
        @enumFromInt(right_id),
        should_ref,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(id));
}

pub export fn persistent_merkle_tree_pool_ref(id: u32) i32 {
    _ = pmt.Node.Pool.ref(&pool, @enumFromInt(id)) catch |e| return toErrCode(e);
    return 0;
}

pub export fn persistent_merkle_tree_pool_unref(id: u32) void {
    pmt.Node.Pool.unref(&pool, @enumFromInt(id));
}

// Node - basic

pub export fn persistent_merkle_tree_node_get_left(id: u32) i32 {
    const node = pmt.Node.Id.getLeft(@enumFromInt(id), &pool) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(node));
}

pub export fn persistent_merkle_tree_node_get_right(id: u32) i32 {
    const node = pmt.Node.Id.getRight(@enumFromInt(id), &pool) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(node));
}

pub export fn persistent_merkle_tree_node_get_hash(id: u32) [*c]const u8 {
    return @ptrCast(pmt.Node.Id.getRoot(@enumFromInt(id), &pool));
}

pub export fn persistent_merkle_tree_node_get_state(id: u32) u32 {
    const state = pmt.Node.Id.getState(@enumFromInt(id), &pool);
    return @intFromEnum(state);
}

// Node - navigation

pub export fn persistent_merkle_tree_node_get_node(root_id: u32, gindex: u64) i32 {
    const id = pmt.Node.Id.getNode(
        @enumFromInt(root_id),
        &pool,
        @enumFromInt(gindex),
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(id));
}

pub export fn persistent_merkle_tree_node_get_node_at_depth(root_id: u32, depth: u8, index: u32) i32 {
    const id = pmt.Node.Id.getNodeAtDepth(
        @enumFromInt(root_id),
        &pool,
        @intCast(depth),
        index,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(id));
}

pub export fn persistent_merkle_tree_node_get_nodes_at_depth(root_id: u32, depth: u8, start_index: u32, out: [*c]u32, out_len: u32) i32 {
    pmt.Node.Id.getNodesAtDepth(
        @enumFromInt(root_id),
        &pool,
        @intCast(depth),
        start_index,
        @ptrCast(out[0..out_len]),
    ) catch |e| return toErrCode(e);
    return 0;
}

pub export fn persistent_merkle_tree_node_set_node(root_id: u32, gindex: u64, node_id: u32) i32 {
    const new_root_id = pmt.Node.Id.setNode(
        @enumFromInt(root_id),
        &pool,
        @enumFromInt(gindex),
        @enumFromInt(node_id),
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(new_root_id));
}

pub export fn persistent_merkle_tree_node_set_node_at_depth(root_id: u32, depth: u8, index: u32, node_id: u32) i32 {
    const new_root_id = pmt.Node.Id.setNodeAtDepth(
        @enumFromInt(root_id),
        &pool,
        @intCast(depth),
        index,
        @enumFromInt(node_id),
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(new_root_id));
}

pub export fn persistent_merkle_tree_node_set_nodes_at_depth(root_id: u32, depth: u8, indices: [*c]const u64, node_ids: [*c]u32, len: u32) i32 {
    const new_root_id = pmt.Node.Id.setNodesAtDepth(
        @enumFromInt(root_id),
        &pool,
        @intCast(depth),
        @ptrCast(indices[0..len]),
        @ptrCast(node_ids[0..len]),
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(new_root_id));
}

pub export fn persistent_merkle_tree_node_set_nodes(root_id: u32, gindices: [*c]const u64, node_ids: [*c]u32, len: u32) i32 {
    const new_root_id = pmt.Node.Id.setNodes(
        @enumFromInt(root_id),
        &pool,
        @ptrCast(gindices[0..len]),
        @ptrCast(node_ids[0..len]),
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(new_root_id));
}

// Node - tree creation

pub export fn persistent_merkle_tree_node_fill_to_depth(leaf: u32, depth: u8, should_ref: bool) i32 {
    const root_id = pmt.Node.fillToDepth(
        &pool,
        @enumFromInt(leaf),
        @intCast(depth),
        should_ref,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(root_id));
}

pub export fn persistent_merkle_tree_node_fill_to_length(leaf: u32, depth: u8, length: u32, should_ref: bool) i32 {
    const root_id = pmt.Node.fillToLength(
        &pool,
        @enumFromInt(leaf),
        @intCast(depth),
        length,
        should_ref,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(root_id));
}

pub export fn persistent_merkle_tree_node_fill_with_contents(leaf_ids: [*c]u32, len: u32, depth: u8, should_ref: bool) i32 {
    const root_id = pmt.Node.fillWithContents(
        &pool,
        @ptrCast(leaf_ids[0..len]),
        @intCast(depth),
        should_ref,
    ) catch |e| return toErrCode(e);
    return @intCast(@intFromEnum(root_id));
}
