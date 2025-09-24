import { toArrayBuffer, type Pointer } from "bun:ffi";
import {binding} from "./binding.ts";
import { throwErr } from "./common.ts";

export function poolInit(size: number): void {
  throwErr(binding.persistent_merkle_tree_pool_init(size));
}

export function poolDeinit(): void {
  binding.persistent_merkle_tree_pool_deinit();
}

export type Node = number & {["persistent_merkle_tree_node"]: never};

export function createLeaf(data: Uint8Array, shouldRef = false): Node {
  if (data.length !== 32) {
    throw new Error("Leaf data must be 32 bytes");
  }
  return throwErr(binding.persistent_merkle_tree_pool_create_leaf(data, shouldRef)) as Node;
}

export function createBranch(left: Node, right: Node, shouldRef = false): Node {
  return throwErr(binding.persistent_merkle_tree_pool_create_branch(left, right, shouldRef)) as Node;
}

export function ref(node: Node): void {
  throwErr(binding.persistent_merkle_tree_pool_ref(node));
}

export function unref(node: Node): void {
  binding.persistent_merkle_tree_pool_unref(node);
}

export function getLeft(node: Node): Node {
  return throwErr(binding.persistent_merkle_tree_node_get_left(node)) as Node;
}

export function getRight(node: Node): Node {
  return throwErr(binding.persistent_merkle_tree_node_get_right(node)) as Node;
}

export function getHash(node: Node): Uint8Array {
  return new Uint8Array(toArrayBuffer(binding.persistent_merkle_tree_node_get_hash(node) as Pointer, 0, 32));
}

export enum NodeType {
  Zero = 0x00000000,
  Leaf = 0x20000000,
  BranchLazy = 0x40000000,
  BranchComputed = 0x60000000,
}

export type NodeState = {
  type: NodeType;
  refCount: number;
}

export function getState(node: Node): NodeState {
  const state = binding.persistent_merkle_tree_node_get_state(node);
  return {
    type: state & 0x60000000,
    refCount: state & 0x1fffffff,
  };
}

export function getNode(rootNode: Node, gindex: number | bigint): Node {
  return throwErr(binding.persistent_merkle_tree_node_get_node(rootNode, gindex)) as Node;
}

export function getNodeAtDepth(rootNode: Node, depth: number, index: number): Node {
  return throwErr(binding.persistent_merkle_tree_node_get_node_at_depth(rootNode, depth, index)) as Node;
}

export function getNodesAtDepth(rootNode: Node, depth: number, startIndex: number, count: number): Uint32Array {
  const nodes = new Uint32Array(count);
  throwErr(binding.persistent_merkle_tree_node_get_nodes_at_depth(rootNode, depth, startIndex, nodes, count));
  return nodes;
}

export function setNode(rootNode: Node, gindex: number | bigint, newNode: Node): Node {
  return throwErr(binding.persistent_merkle_tree_node_set_node(rootNode, gindex, newNode)) as Node;
}

export function setNodeAtDepth(rootNode: Node, depth: number, index: number, newNode: Node): Node {
  return throwErr(binding.persistent_merkle_tree_node_set_node_at_depth(rootNode, depth, index, newNode)) as Node;
}

export function setNodesAtDepth(rootNode: Node, depth: number, indices: number[], newNodes: Node[]): Node {
  if (indices.length !== newNodes.length) {
    throw new Error("Indices and newNodes must have the same length");
  }
  return throwErr(binding.persistent_merkle_tree_node_set_nodes_at_depth(
    rootNode,
    depth,
    new BigUint64Array(indices.map(BigInt)),
    new Uint32Array(newNodes),
    newNodes.length,
  )) as Node;
}

export function setNodes(rootNode: Node, gindices: (number | bigint)[], newNodes: Node[]): Node {
  if (gindices.length !== newNodes.length) {
    throw new Error("Gindices and newNodes must have the same length");
  }
  return throwErr(binding.persistent_merkle_tree_node_set_nodes(
    rootNode,
    new BigUint64Array(gindices.map(BigInt)),
    new Uint32Array(newNodes),
    newNodes.length,
  )) as Node;
}

export function fillToDepth(leaf: Node, depth: number, shouldRef = false): Node {
  return throwErr(binding.persistent_merkle_tree_node_fill_to_depth(leaf, depth, shouldRef)) as Node;
}

export function fillToLength(leaf: Node, depth: number, length: number, shouldRef = false): Node {
  return throwErr(binding.persistent_merkle_tree_node_fill_to_length(leaf, depth, length, shouldRef)) as Node;
}

export function fillWithContents(leaves: Node[], depth: number, shouldRef = false): Node {
  return throwErr(binding.persistent_merkle_tree_node_fill_with_contents(
    new Uint32Array(leaves),
    leaves.length,
    depth,
    shouldRef,
  )) as Node;
}