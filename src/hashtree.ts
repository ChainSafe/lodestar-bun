import {binding} from "./binding.ts";
import { throwErr } from "./common.ts";

export function hash(input: Uint8Array): Uint8Array {
  if (input.length % 64 !== 0) {
    throw new Error("Input length must be a multiple of 64 bytes");
  }
  const out = new Uint8Array(input.length / 2);
  const count = input.length / 64;
  throwErr(binding.hashtree_hash_(out, input, count));
  return out;
}

export function hashInto(input: Uint8Array, output: Uint8Array): void {
  if (input.length % 64 !== 0) {
    throw new Error("Input length must be a multiple of 64 bytes");
  }
  if (output.length !== input.length / 2) {
    throw new Error("Output length must be half of input length");
  }
  const count = input.length / 64;
  throwErr(binding.hashtree_hash_(output, input, count));
}

export function digest64(input: Uint8Array): Uint8Array {
  if (input.length !== 64) {
    throw new Error("Input length must be exactly 64 bytes");
  }
  const out = new Uint8Array(32);
  throwErr(binding.hashtree_digest64(out, input));
  return out;
}

export function digest64Into(input: Uint8Array, output: Uint8Array): void {
  if (input.length !== 64) {
    throw new Error("Input length must be exactly 64 bytes");
  }
  if (output.length !== 32) {
    throw new Error("Output length must be exactly 32 bytes");
  }
  throwErr(binding.hashtree_digest64(output, input));
}

export function digest2Bytes32(a: Uint8Array, b: Uint8Array): Uint8Array {
  if (a.length !== 32 || b.length !== 32) {
    throw new Error("Input lengths must be exactly 32 bytes");
  }
  const out = new Uint8Array(32);
  throwErr(binding.hashtree_digest_2_bytes32(out, a, b));
  return out;
}

export function digest2Bytes32Into(a: Uint8Array, b: Uint8Array, output: Uint8Array): void {
  if (a.length !== 32 || b.length !== 32) {
    throw new Error("Input lengths must be exactly 32 bytes");
  }
  if (output.length !== 32) {
    throw new Error("Output length must be exactly 32 bytes");
  }
  throwErr(binding.hashtree_digest_2_bytes32(output, a, b));
}